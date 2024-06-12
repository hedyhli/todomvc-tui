#!/usr/bin/env nu

use std log

# Patiently waiting for nuon to support closures, if ever.
let impls = {
  "rust-ratatui": {
    file: "src/main.rs",
    build: { |dest| cargo build --release e> /dev/null; cp target/release/todomvc-tui $dest }
  },
  "go-tview": {
    file: "main.go",
    build: { |dest| go build; cp todomvc-tui $dest }
  },
  "zig-libvaxis": {
    file: "src/main.zig",
    build: { |dest|
      for r in [small safe fast] {
        zig build $"--release=($r)"; cp zig-out/bin/todomvc-tui $"($dest)-($r)"
      }
    }
  },
  "nim-illwill": {
    file: "main.nim",
    build: { |dest| nim c main.nim e> /dev/null; cp main $dest }
  },
  "v-term-ui": {
    file: "main.v",
    build: { |dest| v main.v -o $dest }
  },
  "python-textual": {
    file: "main.py",
    build: { |dest| true }
  },
  "go-vaxis": {
    file: "main.go",
    build: { |dest| go build; cp todomvc-tui $dest }
  },
}

def code_table [] {
  (scc --by-file -f csv --sort code
    ...($impls | columns | each {|dir| $'($dir)/($impls | get $dir | get file)' })
    | from csv
    | select Filename Code Comments Complexity
    | rename -c { Filename: "File" }
    | tee { print $in }
    | update File { ($in | split row -n 2 '/' | $"**($in.0)** \(($in.1)\)") }
    | to md)
}

# Build specified impl directories.
def build [...dirs: string] {
  for dir in $dirs {
    let impl = $impls | get $dir
    cd $dir
    log info $"Building ($dir)"
    do $impl.build $"../bin/($dir)"
    cd ..
  }
}

def size_table [] {
  cd bin
  let size = (
    ls
    | sort-by -r size
    | select name size
    | rename Name Size
    | tee { print $in }
    | update Name {
      if ($in | str starts-with 'zig') {
        $in
        | parse --regex '^(?<a>.+)-(?<b>.+)$'
        | $in.0
        | $"($in.a) \(($in.b)\)"
      } else { $in }
    }
    | to md
  )
  cd ..
  $size
}

# Replace stats blocks within fences in the given file.
def write_blocks [filename: string] {
  let code = code_table
  let size = size_table
  let begin_code = "<!--begin-stats-code-->"
  let begin_size = "<!--begin-stats-size-->"
  let end = "<!--end-->"

  def write [s?: string] {
    if $s != null { $"($s)\n" | save -a README.md }
  }

  let file = (open README.md | lines)
  '' | save -f $filename

  # before
  # -------------- <begin-code>
  # replace-code
  # end-code
  # -------------- <end>
  # between
  # -------------- <begin-size>
  # replace-size
  # end-code
  # -------------- <end>
  # after

  mut state = "before"
  for line in $file {
    $state = (
      match $state {
      "before"       if $line == $begin_code => ["replace-code" $begin_code],
      "replace-code" =>                         ["end-code"     $code],
      "end-code"     => (if $line == $end {     ["between"      $end] }      else { [$state null] }),
      "between"      if $line == $begin_size => ["replace-size" $begin_size],
      "replace-size" =>                         ["end-size"     $size],
      "end-size"     => (if $line == $end {     ["after"        $end] }      else { [$state null] }),
      _ => [$state $line]
      }
      | tee { write $in.1 } | $in.0
    )
  }
}

# Update stats in the readme after optionally re-building specified list of impls.
#
# Nothing is rebuilt
#   > .scripts/stats.nu
#
# All known impls rebuilt
#   > .scripts/stats.nu all
#
# Only rebuild these
#   > .scripts/stats.nu zig-libvaxis go-vaxis
def main [
  ...dirs: string  # Directory names of impls. Use 'all' to specify all known impls.
]: nothing -> nothing {
  build ...(if (($dirs | length) != 0 and $dirs.0 == 'all') {
    $impls | columns
  } else {
    $dirs | each { str trim -rc '/' }
  })
  write_blocks "README.md"
}
