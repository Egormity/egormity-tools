import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const SETTINGS_PATH =
    '/home/egormity/.local/share/com.pais.handy/settings_store.json';

const LANGUAGE_NAMES = {
    auto: ['AUTO', 'Auto Detect'],
    ja: ['JA', 'Japanese'],
};

function getModelNames(modelId) {
    if (modelId.includes('Voxtral-Mini-4B-Realtime-2602'))
        return ['Voxtral 4B', 'Voxtral Mini 4B Realtime'];
    if (modelId.includes('cohere-transcribe-03-2026'))
        return ['Cohere', 'Cohere Transcribe'];
    return ['Unknown', 'Unknown model'];
}

const HandyStatusIndicator = GObject.registerClass(
class HandyStatusIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Handy status');

        this._label = new St.Label({
            text: 'Handy',
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'handy-status-label',
        });
        this.add_child(this._label);

        this._languageItem = new PopupMenu.PopupMenuItem('', {
            reactive: false,
        });
        this._modelItem = new PopupMenu.PopupMenuItem('', {
            reactive: false,
        });
        this.menu.addMenuItem(this._languageItem);
        this.menu.addMenuItem(this._modelItem);
    }

    update(languageCode, modelId) {
        const [languageShort, languageFull] =
            LANGUAGE_NAMES[languageCode] ?? ['--', 'Unknown language'];
        const [modelShort, modelFull] = getModelNames(modelId);

        this._label.text = `${languageShort} · ${modelShort}`;
        this._languageItem.label.text = `Language: ${languageFull}`;
        this._modelItem.label.text = `Model: ${modelFull}`;
    }

    showReadError() {
        this._label.text = 'Handy ?';
        this._languageItem.label.text = 'Language: unavailable';
        this._modelItem.label.text = 'Model: unavailable';
    }
});

export default class HandyStatusExtension extends Extension {
    enable() {
        this._indicator = new HandyStatusIndicator();
        Main.panel.addToStatusArea('handy-status', this._indicator, 2, 'right');

        this._settingsFile = Gio.File.new_for_path(SETTINGS_PATH);
        this._settingsDirectory = this._settingsFile.get_parent();
        this._monitor = this._settingsDirectory.monitor_directory(
            Gio.FileMonitorFlags.NONE,
            null
        );
        this._monitorId = this._monitor.connect(
            'changed',
            (_monitor, file, otherFile) => {
                const changedSettings =
                    file?.get_basename() === this._settingsFile.get_basename() ||
                    otherFile?.get_basename() === this._settingsFile.get_basename();
                if (changedSettings)
                    this._scheduleUpdate();
            }
        );

        this._update();
    }

    disable() {
        if (this._updateTimeoutId) {
            GLib.Source.remove(this._updateTimeoutId);
            this._updateTimeoutId = 0;
        }
        if (this._monitor && this._monitorId)
            this._monitor.disconnect(this._monitorId);
        this._monitor?.cancel();
        this._monitor = null;
        this._monitorId = 0;
        this._settingsDirectory = null;
        this._settingsFile = null;
        this._indicator?.destroy();
        this._indicator = null;
    }

    _scheduleUpdate() {
        if (this._updateTimeoutId)
            GLib.Source.remove(this._updateTimeoutId);
        this._updateTimeoutId = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT,
            100,
            () => {
                this._updateTimeoutId = 0;
                this._update();
                return GLib.SOURCE_REMOVE;
            }
        );
    }

    _update() {
        try {
            const [, contents] = this._settingsFile.load_contents(null);
            const document = JSON.parse(new TextDecoder().decode(contents));
            const settings = document.settings ?? {};
            this._indicator.update(
                settings.selected_language ?? '',
                settings.selected_model ?? ''
            );
        } catch (error) {
            console.error(`Handy Status could not read settings: ${error}`);
            this._indicator.showReadError();
        }
    }
}
