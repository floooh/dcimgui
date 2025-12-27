// deno-lint-ignore no-unversioned-import
import { Builder } from 'jsr:@floooh/fibs';
import { addTarget } from './fibs.ts';

export function build(b: Builder) {
    addTarget(b, 'imgui-docking', 'src-docking');
}
