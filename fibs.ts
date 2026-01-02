// deno-lint-ignore no-unversioned-import
import { Builder } from 'jsr:@floooh/fibs';

export function build(b: Builder) {
    addTarget(b, 'imgui', 'src');
}

// common helper function which is also used by fibs-docking.ts
export function addTarget(b: Builder, name: string, subdir: string) {
    b.addTarget(name, 'lib', (t) => {
        t.setDir(subdir);
        t.addSources([
            'cimgui.cpp',
            'cimgui_internal.cpp',
            'imgui_demo.cpp',
            'imgui_draw.cpp',
            'imgui_tables.cpp',
            'imgui_widgets.cpp',
            'imgui.cpp',
        ]);
        t.addIncludeDirectories({ dirs: ['.'], scope: 'public' });
        if (b.isMsvc()) {
            t.addCompileOptions(['/wd4190']);
        }
    });
}
