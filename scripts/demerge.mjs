// scripts/demerge.mjs
// Parses a standalone ABAP PROG and splits it into per-object files
// matching abapgit conventions used in src/01/ and src/02/

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

const args      = process.argv.slice(2);
const inputFile = args[args.indexOf('--input') + 1];
const outClas   = args[args.indexOf('--output-classes') + 1];
const outProg   = args[args.indexOf('--output-prog') + 1];

if (!inputFile || !outClas || !outProg) {
  console.error('Usage: node demerge.mjs --input <file> --output-classes <dir> --output-prog <dir>');
  process.exit(1);
}

const src   = readFileSync(inputFile, 'utf8');
const lines = src.split('\n');

// ── Regex patterns ─────────────────────────────────────────────────────
const RX_CLASS_DEF  = /^CLASS\s+(lcl\w+|lcx\w+|zcl\w+|zcx\w+)\s+DEFINITION/i;
const RX_CLASS_IMPL = /^CLASS\s+(lcl\w+|lcx\w+|zcl\w+|zcx\w+)\s+IMPLEMENTATION/i;
const RX_INTF       = /^INTERFACE\s+(lif\w+|zif\w+)/i;
const RX_ENDCLASS   = /^ENDCLASS\./i;
const RX_ENDINTF    = /^ENDINTERFACE\./i;
const RX_REPORT     = /^REPORT\s+\w+/i;
const RX_DEFERRED   = /^(CLASS\s+(lcl|lcx)\w+|INTERFACE\s+lif\w+)\s+(DEFINITION\s+DEFERRED|DEFERRED)/i;

// ── Name mapping: local → global ───────────────────────────────────────
const nameMap = {
  'lcl_dbuf_auth_checker':       'zcl_dbuf_auth_checker',
  'lcl_dbuf_column_mapper':      'zcl_dbuf_column_mapper',
  'lcl_dbuf_committer_factory':  'zcl_dbuf_committer_factory',
  'lcl_dbuf_dsv_reader':         'zcl_dbuf_dsv_reader',
  'lcl_dbuf_file_handler':       'zcl_dbuf_file_handler',
  'lcl_dbuf_huge_xlsx_reader':   'zcl_dbuf_huge_xlsx_reader',
  'lcl_dbuf_live_committer':     'zcl_dbuf_live_committer',
  'lcl_dbuf_null_committer':     'zcl_dbuf_null_committer',
  'lcl_dbuf_reader_factory':     'zcl_dbuf_reader_factory',
  'lcl_dbuf_result_csv_writer':  'zcl_dbuf_result_csv_writer',
  'lcl_dbuf_result_xlsx_writer': 'zcl_dbuf_result_xlsx_writer',
  'lcl_dbuf_row_validator':      'zcl_dbuf_row_validator',
  'lcl_dbuf_table_validator':    'zcl_dbuf_table_validator',
  'lcl_dbuf_template_builder':   'zcl_dbuf_template_builder',
  'lcl_dbuf_upload_processor':   'zcl_dbuf_upload_processor',
  'lcl_dbuf_writer_factory':     'zcl_dbuf_writer_factory',
  'lcl_dbuf_xlsm_reader':        'zcl_dbuf_xlsm_reader',
  'lcl_dbuf_xlsx_reader':        'zcl_dbuf_xlsx_reader',
  'lcl_dbuf_env':                'zcl_dbuf_env',
  'lcl_dbuf_download':           'zcl_dbuf_download',
  // lcx → zcx (exception classes)
  'lcx_dbuf_error':              'zcx_dbuf_error',
  'lcx_dbuf_auth_error':         'zcx_dbuf_auth_error',
  'lcx_dbuf_file_error':         'zcx_dbuf_file_error',
  'lcx_dbuf_mapping_error':      'zcx_dbuf_mapping_error',
  'lcx_dbuf_validation_error':   'zcx_dbuf_validation_error',
  // lif → zif (interfaces)
  'lif_dbuf_db_committer':       'zif_dbuf_db_committer',
  'lif_dbuf_file_reader':        'zif_dbuf_file_reader',
  'lif_dbuf_result_writer':      'zif_dbuf_result_writer',
};

function globalise(text) {
  let out = text;
  for (const [local, global] of Object.entries(nameMap)) {
    out = out.replace(new RegExp(local, 'gi'), global);
  }
  return out;
}

// ── Extraction state machine ────────────────────────────────────────────
const objects   = [];  // { name, type, lines[] }
const progLines = [];
let current   = null;
let depth     = 0;
let inReport  = false;

for (const line of lines) {
  // Skip DEFERRED forward declarations
  if (RX_DEFERRED.test(line)) continue;

  const mCDef  = line.match(RX_CLASS_DEF);
  const mCImpl = line.match(RX_CLASS_IMPL);
  const mIntf  = line.match(RX_INTF);

  if (mCDef && !current) {
    current = { name: mCDef[1].toLowerCase(), type: 'clas', lines: [line] };
    depth = 1;
  } else if (mCImpl && !current) {
    const existing = objects.find(o => o.name === mCImpl[1].toLowerCase() && o.type === 'clas');
    if (existing) {
      current = existing;
      current.lines.push(line);
      depth = 1;
    } else {
      current = { name: mCImpl[1].toLowerCase(), type: 'clas', lines: [line] };
      depth = 1;
    }
  } else if (mIntf && !current) {
    current = { name: mIntf[1].toLowerCase(), type: 'intf', lines: [line] };
    depth = 1;
  } else if (current) {
    current.lines.push(line);
    if (RX_ENDCLASS.test(line.trim()) || RX_ENDINTF.test(line.trim())) {
      depth--;
      if (depth <= 0) {
        if (!objects.find(o => o.name === current.name)) objects.push(current);
        current = null;
      }
    }
  } else {
    if (RX_REPORT.test(line)) inReport = true;
    if (inReport) progLines.push(line);
  }
}

// ── Write global class / interface files ───────────────────────────────
mkdirSync(outClas, { recursive: true });
for (const obj of objects) {
  const globalName = nameMap[obj.name] ?? obj.name;
  const ext  = obj.type === 'intf' ? 'intf' : 'clas';
  const file = join(outClas, `${globalName}.${ext}.abap`);
  writeFileSync(file, globalise(obj.lines.join('\n')) + '\n', 'utf8');
  console.log(`  ✅ Wrote ${file}`);
}

// ── Write main program ─────────────────────────────────────────────────
mkdirSync(outProg, { recursive: true });
const progFile = join(outProg, 'zdbuf.prog.abap');
writeFileSync(progFile, globalise(progLines.join('\n')) + '\n', 'utf8');
console.log(`  ✅ Wrote ${progFile}`);

console.log(`\nDe-merged ${objects.length} objects + 1 program.`);
