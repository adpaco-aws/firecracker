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
# We remove the one that overrides the implementation
for vmm_version in vm_memory-*.json; do
    if [ $(grep 'dirty_bitmap' ${vmm_version} | wc -l) -gt 0 ]; then
        rm ${vmm_version}.out
    fi
done

touch empty.c
goto-cc --function rmc_compact_harness empty.c *.out -o balloon-all.out
goto-instrument --drop-unused-functions balloon-all.out balloon.out
(time cbmc balloon.out --object-bits 11 --unwind 4 --unwinding-assertions --pointer-check --external-sat-solver ~/kissat/build/kissat)
