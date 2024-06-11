#!/usr/bin/env nu

# Patiently waiting for nuon to support closures.
let impls = [
  {
    dir: "rust-ratatui",
    file: "src/main.rs",
    build: { |dir| cargo build --release; cp target/release/todomvc-tui $"../bin/($dir)" }
  },
  {
    dir: "go-tview",
    file: "main.go",
    build: { |dir| go build; cp todomvc-tui $"../bin/($dir)" }
  },
  {
    dir: "zig-libvaxis",
    file: "src/main.zig",
    build: { |dir|
      for r in [small safe fast] {
        zig build $"--release=($r)"; cp zig-out/bin/todomvc-tui $"../bin/($dir)-($r)"
      }
    }
  },
  {
    dir: "nim-illwill",
    file: "main.nim",
    build: { |dir| nim c main.nim; cp main $"../bin/($dir)" }
  },
  {
    dir: "v-term-ui",
    file: "main.v",
    build: { |dir| v main.v -o $"../bin/($dir)" }
  },
  {
    dir: "python-textual",
    file: "main.py",
    build: {|dir| true }
  },
  {
    dir: "go-vaxis",
    file: "main.go",
    build: { |dir| go build; cp todomvc-tui $"../bin/($dir)" }
  },
]

[
  {
    dir: "rust-ratatui",
    file: "src/main.sr",
    build: { |dir| cargo build --release; cp target/release/todomvc-tui $"../bin/($dir)" }
  },
  {
    dir: "go-tview",
    file: "main.go",
    build: { |dir| go build; cp todomvc-tui $"../bin/($dir)" }
  },
  {
    dir: "zig-libvaxis",
    file: "src/main.zig",
    build: { |dir|
      for r in [small safe fast] {
        zig build $"--release=($r)"; cp zig-out/bin/todomvc-tui $"../bin/($dir)-($r)"
      }
    }
  },
  {
    dir: "nim-illwill",
    file: "main.nim",
    build: { |dir| nim c main.nim; cp main $"../bin/($dir)" }
  },
  {
    dir: "v-term-ui",
    file: "main.v",
    build: { |dir| v main.v -o $"../bin/($dir)" }
  },
  {
    dir: "python-textual",
    file: "main.py",
    build: {|dir| true}
  },
  {
    dir: "go-vaxis",
    file: "main.go",
    build: { |dir| go build; cp todomvc-tui $"../bin/($dir)" }
  },
] | $'($in.dir)/($in.file)'

let code = (
scc --by-file -f csv --sort code
  ...($impls | each { $'($in.dir)/($in.file)' })
  | from csv | select Filename Code Comments Complexity | tee { print $in }
  | update Filename { ($in | split row -n 2 '/' | $"**($in.0)** \(($in.1)\)") }
  | to md
)

# working above

# TODO

for impl in $impls {
  cd $impl.dir
  do $impl.build $impl.dir
  cd ..
}

cd bin
let size = (
  ls | sort-by size | select name size | tee { print $in }
  | update name {
      if ($in | str starts-with 'zig') {
        $in | parse --regex '^(?<a>.+)-(?<b>.+)$' | $in.0
        | $"($in.a) \(($in.b)\)"
      } else { $in }
    }
  | to md
)
cd ..

let begin_code = "<!--begin-stats-code-->\n"
let begin_size = "<!--begin-stats-size-->\n"
let end = "\n<!--end-->"

let file = ( open README.md )
let saveto = "README.md"
'' | save -f $saveto

# 1 keep
# 2 -- begin-code
# 3 replace
# 4 -- end
# 5 keep
# 6 -- begin-size
# 7 replace
# 8 -- end
# 9 keep

# 1, 3-
let code_parts = ( $file | split row $begin_code )
# 3
$code_parts.0 | save -a $saveto

$begin_code | save -a $saveto
$code| save -a $saveto
$end | save -a $saveto

                  # 3-          # 3, 5-7, 9
let end_parts = ( $code_parts.1 | split row $end )
# 5-7        # 5, 7                  # 5
$end_parts.1 | split row $begin_size | $in.0 | save -a $saveto

$begin_size | save -a $saveto
$size| save -a $saveto
$end | save -a $saveto

# 7-          # 7, 9           # 9
$end_parts.2 | save -a $saveto
