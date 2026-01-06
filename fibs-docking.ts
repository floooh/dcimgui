import { Builder } from 'jsr:@floooh/fibs@^1';
import { addTarget } from './fibs.ts';

export function build(b: Builder) {
    addTarget(b, 'imgui-docking', 'src-docking');
}
