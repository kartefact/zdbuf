#!/usr/bin/env node
/**
 * merge.mjs
 * Reads all global class/interface .abap files from src/ (abapgit layout)
 * and produces a single standalone ABAP report at /tmp/zdbuf_standalone.prog.abap
 *
 * Layout expected:
 *   src/<pkg>/<name>.clas.abap          — class main file
 *   src/<pkg>/<name>.intf.abap          — interface file
 *   src/<pkg>/<name>.prog.abap          — main report (contains REPORT stmt)
 *
 * The merger:
 *   1. Reads the main program file (*.prog.abap that contains REPORT)
 *   2. Collects all interface .intf.abap files
 *   3. Collects all class .clas.abap files
 *   4. Emits: REPORT header + DEFERRED blocks + interfaces + classes + main logic
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, extname, basename } from 'path';

const SRC_DIR   = './src';
const OUT_FILE  = '/tmp/zdbuf_standalone.prog.abap';

function walkDir(dir) {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) results.push(...walkDir(full));
    else results.push(full);
  }
  return results;
}

const allFiles = walkDir(SRC_DIR);

// Separate file types
const progFile  = allFiles.find(f => f.endsWith('.prog.abap'));
const intfFiles = allFiles.filter(f => f.endsWith('.intf.abap'));
const clasFiles = allFiles.filter(f =>
  f.endsWith('.clas.abap') &&
  !f.endsWith('.clas.testclasses.abap') &&
  !f.endsWith('.clas.locals_def.abap') &&
  !f.endsWith('.clas.locals_imp.abap')
);

if (!progFile) {
  console.error('No *.prog.abap file found in src/');
  process.exit(1);
}

const progContent = readFileSync(progFile, 'utf8');

// Extract REPORT statement line
const reportLine = progContent.split('\n').find(l => /^REPORT\s+/i.test(l.trim()));
if (!reportLine) {
  console.error('No REPORT statement found in', progFile);
  process.exit(1);
}

// Helper: strip CLASS ... DEFINITION LOAD / INTERFACE ... LOAD stubs if present
function stripLoadStubs(content) {
  return content
    .replace(/^\s*CLASS\s+\S+\s+DEFINITION\s+LOAD\s*\.\s*$/gim, '')
    .replace(/^\s*INTERFACE\s+\S+\s+LOAD\s*\.\s*$/gim, '');
}

// Helper: convert global name (ZCL_/ZIF_) to local (LCL_/LIF_)
function globalToLocal(content) {
  return content
    .replace(/\bZCL_DBUF_/g, 'LCL_DBUF_')
    .replace(/\bZIF_DBUF_/g, 'LIF_DBUF_')
    .replace(/\bZCX_DBUF_/g, 'LCX_DBUF_');
}

// Build DEFERRED declarations
const deferredLines = [];
for (const f of intfFiles) {
  const raw = readFileSync(f, 'utf8');
  const match = raw.match(/^INTERFACE\s+(\S+)/im);
  if (match) deferredLines.push(`INTERFACE ${globalToLocal(match[1]).replace('.', '')} DEFERRED.`);
}
for (const f of clasFiles) {
  const raw = readFileSync(f, 'utf8');
  const match = raw.match(/^CLASS\s+(\S+)\s+DEFINITION/im);
  if (match) deferredLines.push(`CLASS ${globalToLocal(match[1]).replace('.', '')} DEFINITION DEFERRED.`);
}

// Build interface blocks
const intfBlocks = intfFiles.map(f => {
  const raw = readFileSync(f, 'utf8');
  return globalToLocal(stripLoadStubs(raw)).trim();
});

// Build class blocks
const clasBlocks = clasFiles.map(f => {
  const raw = readFileSync(f, 'utf8');
  return globalToLocal(stripLoadStubs(raw)).trim();
});

// Extract the main program body (everything after the last CLASS/INTERFACE block in the prog file)
// For a pure report prog.abap, take everything after the REPORT line
const progLines = progContent.split('\n');
const reportIdx = progLines.findIndex(l => /^REPORT\s+/i.test(l.trim()));
const afterReport = progLines.slice(reportIdx + 1).join('\n').trim();

// Assemble
const parts = [
  reportLine.trim(),
  '',
  deferredLines.join('\n'),
  '',
  intfBlocks.join('\n\n'),
  '',
  clasBlocks.join('\n\n'),
  '',
  afterReport,
];

const output = parts.join('\n').replace(/\n{3,}/g, '\n\n');

writeFileSync(OUT_FILE, output, 'utf8');
console.log(`Standalone written to ${OUT_FILE} (${output.length} chars)`);
