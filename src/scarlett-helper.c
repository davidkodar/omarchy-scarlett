#define _POSIX_C_SOURCE 200809L
#include <alsa/asoundlib.h>
#include <alloca.h>
#include <json-c/json.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <ctype.h>

/* Original implementation. No Scarlett GUI or driver source is incorporated.
 * Only these verified Solo controls may be written. Never restore presets. */
struct control { const char *key, *name; snd_ctl_elem_type_t type; };
static const struct control controls[] = {
    {"air", "Line In 1 Air Capture Switch", SND_CTL_ELEM_TYPE_BOOLEAN},
    {"phantom", "Line In 1 Phantom Power Capture Switch", SND_CTL_ELEM_TYPE_BOOLEAN},
    {"inst", "Line In 2 Level Capture Enum", SND_CTL_ELEM_TYPE_ENUMERATED},
    {"monitor", "Direct Monitor Playback Switch", SND_CTL_ELEM_TYPE_BOOLEAN}
};
static snd_ctl_t *ctl;
static unsigned generation;
static char device[128];
static bool readonly_mode, no_device;
static const char *discovery_error = "Scarlett Solo disconnected";

static void field(json_object *o, const char *k, const char *v) {
    json_object_object_add(o, k, json_object_new_string(v));
}
static void emit(json_object *o) {
    puts(json_object_to_json_string_ext(o, JSON_C_TO_STRING_PLAIN));
    fflush(stdout);
    json_object_put(o);
}
static int info_for(int i, snd_ctl_elem_info_t *info) {
    snd_ctl_elem_info_clear(info);
    snd_ctl_elem_info_set_interface(info, SND_CTL_ELEM_IFACE_MIXER);
    snd_ctl_elem_info_set_name(info, controls[i].name);
    int err = snd_ctl_elem_info(ctl, info);
    if (err < 0) return err;
    if (snd_ctl_elem_info_get_type(info) != controls[i].type ||
        snd_ctl_elem_info_get_count(info) != 1 ||
        !snd_ctl_elem_info_is_readable(info) || snd_ctl_elem_info_is_inactive(info)) return -ENOTSUP;
    if (controls[i].type == SND_CTL_ELEM_TYPE_ENUMERATED) {
        if (snd_ctl_elem_info_get_items(info) != 2) return -ENOTSUP;
        for (unsigned n = 0; n < 2; n++) {
            snd_ctl_elem_info_set_item(info, n);
            if (snd_ctl_elem_info(ctl, info) < 0 ||
                strcmp(snd_ctl_elem_info_get_item_name(info), n ? "Inst" : "Line")) return -ENOTSUP;
        }
    }
    return 0;
}
static int read_control(int i, bool *value, bool *writable) {
    snd_ctl_elem_info_t *info;
    snd_ctl_elem_value_t *v;
    snd_ctl_elem_info_alloca(&info);
    snd_ctl_elem_value_alloca(&v);
    int err = info_for(i, info);
    if (err < 0) return err;
    snd_ctl_elem_value_set_interface(v, SND_CTL_ELEM_IFACE_MIXER);
    snd_ctl_elem_value_set_name(v, controls[i].name);
    err = snd_ctl_elem_read(ctl, v);
    if (err < 0) return err;
    *value = controls[i].type == SND_CTL_ELEM_TYPE_BOOLEAN
        ? snd_ctl_elem_value_get_boolean(v, 0) != 0
        : snd_ctl_elem_value_get_enumerated(v, 0) == 1;
    *writable = !readonly_mode && snd_ctl_elem_info_is_writable(info);
    return 0;
}
static void snapshot(void) {
    json_object *o = json_object_new_object(), *values = json_object_new_object();
    field(o, "type", "state");
    json_object_object_add(o, "connected", json_object_new_boolean(ctl != NULL));
    json_object_object_add(o, "generation", json_object_new_int64(generation));
    field(o, "device", ctl ? device : "");
    field(o, "message", ctl ? (readonly_mode ? "Read-only preview" : "") : discovery_error);
    for (int i = 0; i < 4 && ctl; i++) {
        bool value, writable;
        if (read_control(i, &value, &writable) < 0) continue;
        json_object *c = json_object_new_object();
        json_object_object_add(c, "value", json_object_new_boolean(value));
        json_object_object_add(c, "writable", json_object_new_boolean(writable));
        json_object_object_add(values, controls[i].key, c);
    }
    json_object_object_add(o, "controls", values);
    emit(o);
}
static void disconnect_device(void) {
    if (ctl) snd_ctl_close(ctl);
    ctl = NULL;
    generation++;
}
static void discover(void) {
    if (no_device) return;
    int card = -1, found = 0;
    snd_ctl_t *candidate = NULL;
    discovery_error = "Scarlett Solo disconnected";
    while (snd_card_next(&card) >= 0 && card >= 0) {
        /* Limit v0.1 to the USB product verified on the development device.
         * Other generations must get an explicit profile after testing. */
        char path[96], usb[32], hw[32];
        snprintf(path, sizeof(path), "/proc/asound/card%d/usbid", card);
        FILE *f = fopen(path, "r");
        if (!f) continue;
        bool match = fgets(usb, sizeof(usb), f) && !strcmp(usb, "1235:8211\n");
        fclose(f);
        if (!match) continue;
        snprintf(hw, sizeof(hw), "hw:%d", card);
        snd_ctl_t *c;
        if (snd_ctl_open(&c, hw, SND_CTL_NONBLOCK | (readonly_mode ? SND_CTL_READONLY : 0)) < 0) {
            discovery_error = "Cannot access Scarlett controls";
            continue;
        }
        found++;
        if (candidate) snd_ctl_close(candidate);
        candidate = c;
    }
    if (found != 1) {
        if (candidate) snd_ctl_close(candidate);
        if (found > 1) discovery_error = "Multiple supported Scarlett devices; connect only one";
        return;
    }
    ctl = candidate;
    if (snd_ctl_subscribe_events(ctl, 1) < 0) {
        disconnect_device();
        discovery_error = "Cannot subscribe to Scarlett control changes";
        return;
    }
    snprintf(device, sizeof(device), "Scarlett Solo");
    generation++;
}
static void reply(int64_t id, const char *error) {
    json_object *o = json_object_new_object();
    field(o, "type", "result");
    json_object_object_add(o, "id", json_object_new_int64(id));
    json_object_object_add(o, "ok", json_object_new_boolean(error == NULL));
    if (error) field(o, "error", error);
    emit(o);
}
static void request(const char *line) {
    json_tokener *tok = json_tokener_new();
    json_object *o = json_tokener_parse_ex(tok, line, (int)strlen(line));
    size_t end = json_tokener_get_parse_end(tok);
    bool valid = json_tokener_get_error(tok) == json_tokener_success;
    while (isspace((unsigned char)line[end])) end++;
    valid = valid && !line[end] && json_object_is_type(o, json_type_object);
    json_tokener_free(tok);
    json_object *id, *op, *key, *val, *gen;
    int64_t rid = 0;
    if (valid && json_object_object_get_ex(o, "id", &id) && json_object_is_type(id, json_type_int))
        rid = json_object_get_int64(id);
    if (!valid || rid <= 0 || !json_object_object_get_ex(o, "op", &op) ||
        !json_object_is_type(op, json_type_string)) {
        reply(rid, "Invalid request");
        goto done;
    }
    if (!strcmp(json_object_get_string(op), "get")) { snapshot(); reply(rid, NULL); goto done; }
    if (strcmp(json_object_get_string(op), "set") ||
        !json_object_object_get_ex(o, "key", &key) || !json_object_is_type(key, json_type_string) ||
        !json_object_object_get_ex(o, "value", &val) || !json_object_is_type(val, json_type_boolean) ||
        !json_object_object_get_ex(o, "generation", &gen) || !json_object_is_type(gen, json_type_int)) {
        reply(rid, "Invalid set request"); goto done;
    }
    int i;
    for (i = 0; i < 4; i++) if (!strcmp(json_object_get_string(key), controls[i].key)) break;
    if (i == 4) { reply(rid, "Unknown control"); goto done; }
    if (readonly_mode) { reply(rid, "Read-only mode"); goto done; }
    if (!ctl || json_object_get_int64(gen) != generation) {
        reply(rid, "Device disconnected or changed; refresh and try again"); goto done;
    }
    bool actual, writable;
    int err = read_control(i, &actual, &writable);
    if (err < 0 || !writable) { reply(rid, "Control unavailable or read-only"); goto done; }
    snd_ctl_elem_value_t *v;
    snd_ctl_elem_value_alloca(&v);
    snd_ctl_elem_value_set_interface(v, SND_CTL_ELEM_IFACE_MIXER);
    snd_ctl_elem_value_set_name(v, controls[i].name);
    bool desired = json_object_get_boolean(val);
    if (controls[i].type == SND_CTL_ELEM_TYPE_BOOLEAN) snd_ctl_elem_value_set_boolean(v, 0, desired);
    else snd_ctl_elem_value_set_enumerated(v, 0, desired ? 1 : 0);
    err = snd_ctl_elem_write(ctl, v);
    if (err < 0) { reply(rid, snd_strerror(err)); snapshot(); goto done; }
    err = read_control(i, &actual, &writable);
    snapshot();
    reply(rid, err < 0 ? "Could not verify write" : actual != desired ? "Device did not accept setting" : NULL);
 done:
    if (o) json_object_put(o);
}
int main(int argc, char **argv) {
    bool once = false;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--read-only")) readonly_mode = true;
        else if (!strcmp(argv[i], "--no-device")) no_device = true;
        else if (!strcmp(argv[i], "--once")) { once = true; readonly_mode = true; }
        else { fprintf(stderr, "Usage: %s [--read-only] [--once] [--no-device]\n", argv[0]); return 2; }
    }
    discover(); snapshot();
    if (once) { disconnect_device(); return 0; }
    snd_ctl_event_t *event; snd_ctl_event_alloca(&event);
    char input[4096]; size_t used = 0; bool overflow = false;
    while (true) {
        int count = ctl ? snd_ctl_poll_descriptors_count(ctl) : 0;
        if (count < 0 || count > 64) { disconnect_device(); snapshot(); continue; }
        struct pollfd fds[65] = {{.fd = STDIN_FILENO, .events = POLLIN}};
        if (ctl && snd_ctl_poll_descriptors(ctl, fds + 1, (unsigned)count) < 0) {
            disconnect_device(); snapshot(); continue;
        }
        int ready = poll(fds, (nfds_t)count + 1, ctl ? -1 : 1500);
        if (ready < 0) { if (errno == EINTR) continue; break; }
        if (!ready) {
            const char *previous_error = discovery_error;
            discover();
            if (ctl || strcmp(previous_error, discovery_error)) snapshot();
            continue;
        }
        /* Drain device events before accepting commands. A stale generation
         * must never write to a newly attached device. */
        if (ctl) {
            unsigned short revents = 0;
            int err = snd_ctl_poll_descriptors_revents(ctl, fds + 1, (unsigned)count, &revents);
            if (err < 0 || (revents & (POLLERR | POLLHUP | POLLNVAL))) { disconnect_device(); snapshot(); }
            else if (revents & POLLIN) {
                while ((err = snd_ctl_read(ctl, event)) > 0) {}
                if (err < 0 && err != -EAGAIN) disconnect_device();
                snapshot();
            }
        }
        if (fds[0].revents & (POLLIN | POLLHUP)) {
            char chunk[512]; ssize_t n = read(STDIN_FILENO, chunk, sizeof(chunk));
            if (n <= 0) break;
            for (ssize_t j = 0; j < n; j++) {
                if (chunk[j] == '\n') {
                    if (overflow) reply(0, "Request too long or contains NUL");
                    else { input[used] = 0; request(input); }
                    used = 0; overflow = false;
                } else if (chunk[j] == 0 || used == sizeof(input) - 1) overflow = true;
                else if (!overflow) input[used++] = chunk[j];
            }
        }
        if (fds[0].revents & (POLLERR | POLLNVAL)) break;
    }
    disconnect_device();
    return 0;
}
