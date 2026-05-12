#!/usr/bin/env node
/**
 * demerge.mjs
 * Reads a standalone ABAP report (single file with local classes LCL_/LIF_/LCX_)
 * and splits it back into abapgit global class layout under /tmp/zdbuf_demerged/src/
 *
 * Naming:
 *   LCL_DBUF_* -> ZCL_DBUF_*
 *   LIF_DBUF_* -> ZIF_DBUF_*
 *   LCX_DBUF_* -> ZCX_DBUF_*
 *
 * Output structure mirrors existing src/ abapgit layout:
 *   /tmp/zdbuf_demerged/src/<pkg>/<name>.clas.abap
 *   /tmp/zdbuf_demerged/src/<pkg>/<name>.intf.abap
 */

import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync } from 'fs';
import { join } from 'path';

const STANDALONE = './zdbuf_standalone.prog.abap';
const OUT_DIR    = '/tmp/zdbuf_demerged';
const SRC_PKG    = 'src/01'; // default package folder

function localToGlobal(str) {
  return str
    .replace(/\bLCL_DBUF_/g, 'ZCL_DBUF_')
    .replace(/\bLIF_DBUF_/g, 'ZIF_DBUF_')
    .replace(/\bLCX_DBUF_/g, 'ZCX_DBUF_');
}

function toFileName(globalName, type) {
  const lower = globalName.toLowerCase();
  return type === 'intf'
    ? `${lower}.intf.abap`
    : `${lower}.clas.abap`;
}

const content = readFileSync(STANDALONE, 'utf8');
const lines   = content.split('\n');

// State machine to extract blocks
const blocks = [];   // { type: 'intf'|'clas'|'prog', name, lines[] }
let current = null;
let depth   = 0;

for (const line of lines) {
  const trimmed = line.trimEnd();

  // Interface start
  const intfStart = trimmed.match(/^INTERFACE\s+(\S+)(?!\s+DEFERRED)/i);
  if (intfStart && !current) {
    current = { type: 'intf', name: localToGlobal(intfStart[1].replace('.', '')), lines: [] };
    depth = 1;
    current.lines.push(localToGlobal(trimmed));
    continue;
  }

  // Class definition/implementation start
  const clasStart = trimmed.match(/^CLASS\s+(\S+)\s+(DEFINITION|IMPLEMENTATION)/i);
  if (clasStart && !current) {
    const existing = blocks.find(b => b.name === localToGlobal(clasStart[1].replace('.', '')) && b.type === 'clas');
    if (existing) {
      current = existing;
      depth = 1;
      current.lines.push(localToGlobal(trimmed));
    } else {
      current = { type: 'clas', name: localToGlobal(clasStart[1].replace('.', '')), lines: [] };
      depth = 1;
      current.lines.push(localToGlobal(trimmed));
      blocks.push(current);
    }
    continue;
  }

  if (current) {
    current.lines.push(localToGlobal(trimmed));
    // Track ENDCLASS / ENDINTERFACE
    if (/^ENDCLASS\s*\.?\s*$/i.test(trimmed) || /^ENDINTERFACE\s*\.?\s*$/i.test(trimmed)) {
      depth--;
      if (depth <= 0) {
        if (!blocks.includes(current)) blocks.push(current);
        current = null;
      }
    }
  }
}

// Write output files
const outSrc = join(OUT_DIR, SRC_PKG);
mkdirSync(outSrc, { recursive: true });

for (const block of blocks) {
  const fileName = toFileName(block.name, block.type);
  const filePath = join(outSrc, fileName);
  writeFileSync(filePath, block.lines.join('\n') + '\n', 'utf8');
  console.log(`  written: ${filePath}`);
}

console.log(`\nDemerged ${blocks.length} blocks to ${outSrc}`);
