#[cfg(rmc)]
mod rmc {
    use vm_memory::{GuestAddress, GuestMemoryMmap};
    use super::super::Request;
    use super::super::super::DescriptorChain;

    const MEM_SIZE: usize = 0x18_0000;
    static mut TRACK_CHECKED_OFFSET_NONE: bool = false;
    static mut TRACK_READ_OBJ: Option<GuestAddress> = None;

    fn __nondet<T>() -> T {
        unimplemented!()
    }

    fn create_guest_mem() -> GuestMemoryMmap {
        GuestMemoryMmap::from_ranges(&[(GuestAddress(0x0), MEM_SIZE)]).unwrap()
    }

    fn is_nonzero_pow2(x: u16) -> bool {
        unsafe { (x != 0) && ((x & (x - 1)) == 0) }
    }

    #[no_mangle]
    fn rmc_harness() {
        let mem = create_guest_mem();
        let queue_size: u16 = __nondet();
        if !is_nonzero_pow2(queue_size) {
            return;
        }
        let index: u16 = __nondet();
        let desc_table = GuestAddress(__nondet::<u64>() & 0xffff_ffff_ffff_fff0);
        let desc = DescriptorChain::checked_new(&mem, desc_table, queue_size, index);
        match desc {
            Some(x) => {
                let addr = desc_table.0 + (index as u64) * 16; //< this arithmetic cannot fail
                unsafe {
                    if let Some(v) = TRACK_READ_OBJ {
                        assert!(v.0 == addr)
                    }
                }
                assert!(x.index == index);
                assert!(x.index < queue_size);
                if x.has_next() {
                    assert!(x.next < queue_size);
                }
                let req = Request::parse(&x, &mem);
                if let Ok(req) = req {
                    unsafe {
                        assert!(!TRACK_CHECKED_OFFSET_NONE);
                    }
                }
            }
            None => assert!(true),
        };
    }
}
