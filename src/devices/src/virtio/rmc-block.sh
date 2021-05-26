set -ex

PATH=$PATH:~/rmc/scripts/

# Clean and `cargo build` with RMC
rm -rf ../../../../build
RUSTFLAGS="-Z trim-diagnostic-paths=no -Z codegen-backend=gotoc --cfg=rmc" RUSTC=rmc-rustc cargo build --target x86_64-unknown-linux-gnu
cd ../../../../build/cargo_target/x86_64-unknown-linux-gnu/debug/deps/

# We compile all crates to not miss any dependencies
for j in *.json; do
    symtab2gb $j --out $j.out
done

# Two versions of vm_memory are compiled
# We remove the one that does not include 'dirty_bitmap'
for vmm_version in vm_memory-*.json; do
    if [ $(grep 'dirty_bitmap' ${vmm_version} | wc -l) -eq 0 ]; then
        rm ${vmm_version}.out
    fi
done

touch empty.c
goto-cc --function rmc_harness empty.c *.out -o block-all.out
goto-instrument --drop-unused-functions block-all.out block.out
(time cbmc block.out --object-bits 11 --unwind 2 --unwinding-assertions --pointer-check --stop-on-fail --external-sat-solver ~/kissat/build/kissat)