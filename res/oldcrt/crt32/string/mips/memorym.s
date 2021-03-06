//      TITLE("Compare, Move, and Fill Memory Support")
//++
//
// Copyright (c) 1990  Microsoft Corporation
//
// Module Name:
//
//    memory.s
//
// Abstract:
//
//    This module implements functions to compare, move, zero, and fill
//    blocks of memory. If the memory is aligned, then these functions
//    are very efficient.
//
//    N.B. These routines MUST preserve all floating state since they are
//        frequently called from interrupt service routines that normally
//        do not save or restore floating state.
//
// Author:
//
//    David N. Cutler (davec) 11-Apr-1990
//
// Environment:
//
//    User or Kernel mode.
//
// Revision History:
//    02/02/94 RDL This is a cloned version of ntos\rtl\mips\xxmvmem.s
//                 Used RtlMoveMemory and RtlFillMemory.
//    02/15/94 RDL Used RtlCompareMemory, changed return code for memcmp.
//    02/22/94 RDL Fixed memcmp, zero length and equal aligned 32-byte
//                 buffers return wrong code.
//
//--

#include "ksmips.h"
        SBTTL("Compare Memory")

//++
//
// ULONG
// RtlCompareMemory (
//    IN PVOID Source1,
//    IN PVOID Source2,
//    IN ULONG Length
//    )
//
// Routine Description:
//
//    This function compares two blocks of memory and returns the number
//    of bytes that compared equal.
//
// Arguments:
//
//    Source1 (a0) - Supplies a pointer to the first block of memory to
//       compare.
//
//    Source2 (a1) - Supplies a pointer to the second block of memory to
//       compare.
//
//    Length (a2) - Supplies the length, in bytes, of the memory to be
//       compared.
//
// Return Value:
//
//    zero if source1 == source2
//    -1   if source1 <  source2
//     1   if source1 >  source2
//    value. If all bytes compared equal, then the length of the orginal
//    block of memory is returned.
//
//--

        LEAF_ENTRY(memcmp)

        addu    a3,a0,a2                // compute ending address of source1
        move    v0,a2                   // save length of comparison
        and     t0,a2,32 - 1            // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        addu    t4,a0,t1                // compute ending block address
        beq     zero,t1,100f            // if eq, no 32-byte block to compare
        or      t0,a0,a1                // merge and isolate alignment bits
        and     t0,t0,0x3               //
        bne     zero,t0,CompareUnaligned // if ne, unalignment comparison

//
// Compare memory aligned.
//

CompareAligned:                         //

        .set    noreorder
10:     lw      t0,0(a0)                // compare 32-byte block
        lw      t1,0(a1)                //
        lw      t2,4(a0)                //
        bne     t0,t1,90f               // if ne, first word not equal
        lw      t3,4(a1)                //
        lw      t0,8(a0)                //
        bne     t2,t3,20f               // if ne, second word not equal
        lw      t1,8(a1)                //
        lw      t2,12(a0)               //
        bne     t0,t1,30f               // if ne, third word not equal
        lw      t3,12(a1)               //
        lw      t0,16(a0)               //
        bne     t2,t3,40f               // if ne, fourth word not equal
        lw      t1,16(a1)               //
        lw      t2,20(a0)               //
        bne     t0,t1,50f               // if ne, fifth word not equal
        lw      t3,20(a1)               //
        lw      t0,24(a0)               //
        bne     t2,t3,60f               // if ne, sixth word not equal
        lw      t1,24(a1)               //
        lw      t2,28(a0)               //
        bne     t0,t1,70f               // if ne, seventh word not equal
        lw      t3,28(a1)               //
        addu    a0,a0,32                // advance source1 to next block
        bne     t2,t3,80f               // if ne, eighth word not equal
        nop                             //
        bne     a0,t4,10b               // if ne, more 32-byte blocks to compare
        addu    a1,a1,32                // update source2 address
        .set    reorder

        subu    a2,a3,a0                // compute remaining bytes
        b       100f                    //

//
// Compare memory unaligned.
//

CompareUnaligned:                       //
        and     t0,a0,0x3               // isolate source1 alignment
        bne     zero,t0,CompareUnalignedS1 // if ne, source1 unaligned

//
// Source1 is aligned and Source2 is unaligned.
//

CompareUnalignedS2:                     //

        .set    noreorder
10:     lw      t0,0(a0)                // compare 32-byte block
        lwr     t1,0(a1)                //
        lwl     t1,3(a1)                //
        lw      t2,4(a0)                //
        bne     t0,t1,90f               // if ne, first word not equal
        lwr     t3,4(a1)                //
        lwl     t3,7(a1)                //
        lw      t0,8(a0)                //
        bne     t2,t3,20f               // if ne, second word not equal
        lwr     t1,8(a1)                //
        lwl     t1,11(a1)               //
        lw      t2,12(a0)               //
        bne     t0,t1,30f               // if ne, third word not equal
        lwr     t3,12(a1)               //
        lwl     t3,15(a1)               //
        lw      t0,16(a0)               //
        bne     t2,t3,40f               // if ne, fourth word not equal
        lwr     t1,16(a1)               //
        lwl     t1,19(a1)               //
        lw      t2,20(a0)               //
        bne     t0,t1,50f               // if ne, fifth word not equal
        lwr     t3,20(a1)               //
        lwl     t3,23(a1)               //
        lw      t0,24(a0)               //
        bne     t2,t3,60f               // if ne, sixth word not equal
        lwr     t1,24(a1)               //
        lwl     t1,27(a1)               //
        lw      t2,28(a0)               //
        bne     t0,t1,70f               // if ne, seventh word not equal
        lwr     t3,28(a1)               //
        lwl     t3,31(a1)               //
        addu    a0,a0,32                // advance source1 to next block
        bne     t2,t3,80f               // if ne, eighth word not equal
        nop                             //
        bne     a0,t4,10b               // if ne, more 32-byte blocks to compare
        addu    a1,a1,32                // update source2 address
        .set    reorder

        subu    a2,a3,a0                // compute remaining bytes
        b       100f                    //

//
// Source1 is unaligned, check Source2 alignment.
//

CompareUnalignedS1:                     //
        and     t0,a1,0x3               // isolate Source2 alignment
        bne     zero,t0,CompareUnalignedS1AndS2 // if ne, Source2 unaligned

//
// Source1 is unaligned and Source2 is aligned.
//

        .set    noreorder
10:     lwr     t0,0(a0)                // compare 32-byte block
        lwl     t0,3(a0)                //
        lw      t1,0(a1)                //
        lwr     t2,4(a0)                //
        lwl     t2,7(a0)                //
        bne     t0,t1,90f               // if ne, first word not equal
        lw      t3,4(a1)                //
        lwr     t0,8(a0)                //
        lwl     t0,11(a0)               //
        bne     t2,t3,20f               // if ne, second word not equal
        lw      t1,8(a1)                //
        lwr     t2,12(a0)               //
        lwl     t2,15(a0)               //
        bne     t0,t1,30f               // if ne, third word not equal
        lw      t3,12(a1)               //
        lwr     t0,16(a0)               //
        lwl     t0,19(a0)               //
        bne     t2,t3,40f               // if ne, fourth word not equal
        lw      t1,16(a1)               //
        lwr     t2,20(a0)               //
        lwl     t2,23(a0)               //
        bne     t0,t1,50f               // if ne, fifth word not equal
        lw      t3,20(a1)               //
        lwr     t0,24(a0)               //
        lwl     t0,27(a0)               //
        bne     t2,t3,60f               // if ne, sixth word not equal
        lw      t1,24(a1)               //
        lwr     t2,28(a0)               //
        lwl     t2,31(a0)               //
        bne     t0,t1,70f               // if ne, seventh word not equal
        lw      t3,28(a1)               //
        addu    a0,a0,32                // advance source1 to next block
        bne     t2,t3,80f               // if ne, eighth word not equal
        nop                             //
        bne     a0,t4,10b               // if ne, more 32-byte blocks to compare
        addu    a1,a1,32                // update source2 address
        .set    reorder

        subu    a2,a3,a0                // compute remaining bytes
        b       100f                    //

//
// Source1 and Source2 are unaligned.
//

CompareUnalignedS1AndS2:                //

        .set    noreorder
10:     lwr     t0,0(a0)                // compare 32-byte block
        lwl     t0,3(a0)                //
        lwr     t1,0(a1)                //
        lwl     t1,3(a1)                //
        lwr     t2,4(a0)                //
        lwl     t2,7(a0)                //
        bne     t0,t1,90f               // if ne, first word not equal
        lwr     t3,4(a1)                //
        lwl     t3,7(a1)                //
        lwr     t0,8(a0)                //
        lwl     t0,11(a0)               //
        bne     t2,t3,20f               // if ne, second word not equal
        lwr     t1,8(a1)                //
        lwl     t1,11(a1)               //
        lwr     t2,12(a0)               //
        lwl     t2,15(a0)               //
        bne     t0,t1,30f               // if ne, third word not equal
        lwr     t3,12(a1)               //
        lwl     t3,15(a1)               //
        lwr     t0,16(a0)               //
        lwl     t0,19(a0)               //
        bne     t2,t3,40f               // if ne, fourth word not equal
        lwr     t1,16(a1)               //
        lwl     t1,19(a1)               //
        lwr     t2,20(a0)               //
        lwl     t2,23(a0)               //
        bne     t0,t1,50f               // if ne, fifth word not equal
        lwr     t3,20(a1)               //
        lwl     t3,23(a1)               //
        lwr     t0,24(a0)               //
        lwl     t0,27(a0)               //
        bne     t2,t3,60f               // if ne, sixth word not equal
        lwr     t1,24(a1)               //
        lwl     t1,27(a1)               //
        lwr     t2,28(a0)               //
        lwl     t2,31(a0)               //
        bne     t0,t1,70f               // if ne, seventh word not equal
        lwr     t3,28(a1)               //
        lwl     t3,31(a1)               //
        addu    a0,a0,32                // advance source1 to next block
        bne     t2,t3,80f               // if ne, eighth word not equal
        nop                             //
        bne     a0,t4,10b               // if ne, more 32-byte blocks to compare
        addu    a1,a1,32                // update source2 address
        .set    reorder

        subu    a2,a3,a0                // compute remaining bytes
        b       100f                    //

//
// Adjust source1 and source2 pointers dependent on position of miscompare in
// block.
//

20:    addu     a0,a0,4                // mismatch on second word
       addu     a1,a1,4                //
       b        90f                    //

30:    addu     a0,a0,8                // mismatch on third word
       addu     a1,a1,8                //
       b        90f                    //

40:    addu     a0,a0,12               // mistmatch on fourth word
       addu     a1,a1,12               //
       b        90f                    //

50:    addu     a0,a0,16               // mismatch on fifth word
       addu     a1,a1,16               //
       b        90f                    //

60:    addu     a0,a0,20               // mismatch on sixth word
       addu     a1,a1,20               //
       b        90f                    //

70:    addu     a0,a0,24               // mismatch on seventh word
       addu     a1,a1,24               //
       b        90f                    //

80:    subu     a0,a0,4                // mismatch on eighth word
       addu     a1,a1,28               //
90:    subu     a2,a3,a0               // compute remaining bytes

//
// Compare 1-byte blocks.
//

100:    addu    t2,a0,a2                // compute ending block address
        beq     zero,a2,120f            // if eq, buffers equal
110:    lb      t0,0(a0)                // compare 1-byte block
        lb      t1,0(a1)                //
        addu    a1,a1,1                 // advance pointers to next block
        bne     t0,t1,130f              // if ne, byte not equal
        addu    a0,a0,1                 //
        bne     a0,t2,110b              // if ne, more 1-byte block to zero

120:    move    v0,zero                 // source1 == source2
        j       ra                      // return

130:    sltu    v0,t1,t0                // compare source1 to source2
        beq     v0,zero,140f
        j       ra                      // return, source1 > source2
140:
        li      v0,-1
        j       ra                      // return, source1 < source2

        .end    memcmp

        SBTTL("Move Memory")
//++
//
// VOID
// RtlMoveMemory (
//    IN PVOID Destination,
//    IN PVOID Source,
//    IN ULONG Length
//    )
//
// Routine Description:
//
//    This function moves memory either forward or backward, aligned or
//    unaligned, in 32-byte blocks, followed by 4-byte blocks, followed
//    by any remaining bytes.
//
// Arguments:
//
//    Destination (a0) - Supplies a pointer to the destination address of
//       the move operation.
//
//    Source (a1) - Supplies a pointer to the source address of the move
//       operation.
//
//    Length (a2) - Supplies the length, in bytes, of the memory to be moved.
//
// Return Value:
//
//    None.
//
//    N.B. The C runtime entry points memmove and memcpy are equivalent to
//         RtlMoveMemory thus alternate entry points are provided for these
//         routines.
//--

        LEAF_ENTRY(memmove)
        j      memcpy
        .end   memmove

        LEAF_ENTRY(memcpy)

        move    v0,a0                   // return destination

//
// If the source address is less than the destination address and source
// address plus the length of the move is greater than the destination
// address, then the source and destination overlap such that the move
// must be performed backwards.
//

10:     bgeu    a1,a0,MoveForward       // if geu, no overlap possible
        addu    t0,a1,a2                // compute source ending address
        bgtu    t0,a0,MoveBackward      // if gtu, source and destination overlap

//
// Move memory forward aligned and unaligned.
//

MoveForward:                            //
        sltu    t0,a2,4                 // check if less than four bytes
        bne     zero,t0,50f             // if ne, less than four bytes to move
        xor     t0,a0,a1                // compare alignment bits
        and     t0,t0,0x3               // isolate alignment comparison
        bne     zero,t0,MoveForwardUnaligned // if ne, incompatible alignment

//
// Move memory forward aligned.
//

MoveForwardAligned:                     //
        subu    t0,zero,a0              // compute bytes until aligned
        and     t0,t0,0x3               // isolate residual byte count
        subu    a2,a2,t0                // reduce number of bytes to move
        beq     zero,t0,10f             // if eq, already aligned
        lwr     t1,0(a1)                // move unaligned bytes
        swr     t1,0(a0)                //
        addu    a0,a0,t0                // align destination address
        addu    a1,a1,t0                // align source address

//
// Check for 32-byte blocks to move.
//

10:     and     t0,a2,32 - 1            // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        addu    t8,a0,t1                // compute ending block address
        beq     zero,t1,30f             // if eq, no 32-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 32-byte blocks.
//

#if defined(R4000)

        and     t0,a0,1 << 2            // check if destination quadword aligned
        beq     zero,t0,15f             // if eq, destination quadword aligned
        lw      t0,0(a1)                // get source longword
        addu    a1,a1,4                 // align source address
        sw      t0,0(a0)                // store destination longword
        addu    a0,a0,4                 // align destination address
        addu    a2,a2,t1                // recompute bytes to move
        subu    a2,a2,4                 // reduce count by 4
        b       10b                     //

//
// The destination is quadword aligned, check the source operand.
//

15:     and     t0,a1,1 << 2            // check if source quadword aligned
        beq     zero,t0,22f             // if eq, source quadword aligned

//
// The source is longword aligned and the destination is quadword aligned.
//

        .set    noreorder
20:     lwc1    f0,0(a1)                // move 32-byte block
        lwc1    f1,4(a1)                //
        lwc1    f2,8(a1)                //
        lwc1    f3,12(a1)               //
        lwc1    f4,16(a1)               //
        lwc1    f5,20(a1)               //
        lwc1    f6,24(a1)               //
        lwc1    f7,28(a1)               //
        sdc1    f0,0(a0)                //
        sdc1    f2,8(a0)                //
        sdc1    f4,16(a0)               //
        sdc1    f6,24(a0)               //
        addu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        addu    a1,a1,32                //
        .set    reorder

        b       30f                     //

//
// Both the source and the destination are quadword aligned.
//

22:     and     t0,t1,1 << 5            // test if even number of 32-byte blocks
        beq     zero,t0,26f             // if eq, even number of 32-byte blocks

//
// Move one 32-byte block quadword aligned.
//

        .set    noreorder
        ldc1    f0,0(a1)                // move 32-byte block
        ldc1    f2,8(a1)                //
        ldc1    f4,16(a1)               //
        ldc1    f6,24(a1)               //
        sdc1    f0,0(a0)                //
        sdc1    f2,8(a0)                //
        sdc1    f4,16(a0)               //
        sdc1    f6,24(a0)               //
        addu    a0,a0,32                // advance pointers to next block
        beq     a0,t8,30f               // if eq, end of block
        addu    a1,a1,32                //
        .set    reorder

//
// Move 64-byte blocks quadword aligned.
//

        .set    noreorder
26:     ldc1    f0,0(a1)                // move 64-byte block
        ldc1    f2,8(a1)                //
        ldc1    f4,16(a1)               //
        ldc1    f6,24(a1)               //
        ldc1    f8,32(a1)               //
        ldc1    f10,40(a1)              //
        ldc1    f12,48(a1)              //
        ldc1    f14,56(a1)              //
        sdc1    f0,0(a0)                //
        sdc1    f2,8(a0)                //
        sdc1    f4,16(a0)               //
        sdc1    f6,24(a0)               //
        sdc1    f8,32(a0)               //
        sdc1    f10,40(a0)              //
        sdc1    f12,48(a0)              //
        sdc1    f14,56(a0)              //
        addu    a0,a0,64                // advance pointers to next block
        bne     a0,t8,26b               // if ne, more 64-byte blocks to zero
        addu    a1,a1,64                //
        .set    reorder

#endif

//
// The source is longword aligned and the destination is longword aligned.
//

#if defined(R3000)

        .set    noreorder
20:     lw      t0,0(a1)                // move 32-byte block
        lw      t1,4(a1)                //
        lw      t2,8(a1)                //
        lw      t3,12(a1)               //
        lw      t4,16(a1)               //
        lw      t5,20(a1)               //
        lw      t6,24(a1)               //
        lw      t7,28(a1)               //
        sw      t0,0(a0)                //
        sw      t1,4(a0)                //
        sw      t2,8(a0)                //
        sw      t3,12(a0)               //
        sw      t4,16(a0)               //
        sw      t5,20(a0)               //
        sw      t6,24(a0)               //
        sw      t7,28(a0)               //
        addu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        addu    a1,a1,32                //
        .set    reorder

#endif

//
// Check for 4-byte blocks to move.
//

30:     and     t0,a2,4 - 1             // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        addu    t2,a0,t1                // compute ending block address
        beq     zero,t1,50f             // if eq, no 4-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 4-byte block.
//

        .set    noreorder
40:     lw      t0,0(a1)                // move 4-byte block
        addu    a0,a0,4                 // advance pointers to next block
        sw      t0,-4(a0)               //
        bne     a0,t2,40b               // if ne, more 4-byte blocks to zero
        addu    a1,a1,4                 //
        .set    reorder

//
// Move 1-byte blocks.
//

50:     addu    t2,a0,a2                // compute ending block address
        beq     zero,a2,70f             // if eq, no bytes to zero

        .set    noreorder
60:     lb      t0,0(a1)                // move 1-byte block
        addu    a0,a0,1                 // advance pointers to next block
        sb      t0,-1(a0)               //
        bne     a0,t2,60b               // if ne, more 1-byte block to zero
        addu    a1,a1,1                 //
        .set    reorder

70:     j       ra                      // return

//
// Move memory forward unaligned.
//

MoveForwardUnaligned:                   //
        subu    t0,zero,a0              // compute bytes until aligned
        and     t0,t0,0x3               // isolate residual byte count
        subu    a2,a2,t0                // reduce number of bytes to move
        beq     zero,t0,10f             // if eq, already aligned
        lwr     t1,0(a1)                // move unaligned bytes
        lwl     t1,3(a1)                //
        swr     t1,0(a0)                //
        addu    a0,a0,t0                // align destination address
        addu    a1,a1,t0                // update source address

//
// Check for 32-byte blocks to move.
//

10:     and     t0,a2,32 - 1            // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        addu    t8,a0,t1                // compute ending block address
        beq     zero,t1,30f             // if eq, no 32-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 32-byte block.
//

        .set    noreorder
20:     lwr     t0,0(a1)                // move 32-byte block
        lwl     t0,3(a1)                //
        lwr     t1,4(a1)                //
        lwl     t1,7(a1)                //
        lwr     t2,8(a1)                //
        lwl     t2,11(a1)               //
        lwr     t3,12(a1)               //
        lwl     t3,15(a1)               //
        lwr     t4,16(a1)               //
        lwl     t4,19(a1)               //
        lwr     t5,20(a1)               //
        lwl     t5,23(a1)               //
        lwr     t6,24(a1)               //
        lwl     t6,27(a1)               //
        lwr     t7,28(a1)               //
        lwl     t7,31(a1)               //
        sw      t0,0(a0)                //
        sw      t1,4(a0)                //
        sw      t2,8(a0)                //
        sw      t3,12(a0)               //
        sw      t4,16(a0)               //
        sw      t5,20(a0)               //
        sw      t6,24(a0)               //
        sw      t7,28(a0)               //
        addu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        addu    a1,a1,32                //
        .set    reorder

//
// Check for 4-byte blocks to move.
//

30:     and     t0,a2,4 - 1             // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        addu    t2,a0,t1                // compute ending block address
        beq     zero,t1,50f             // if eq, no 4-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 4-byte block.
//

        .set    noreorder
40:     lwr     t0,0(a1)                // move 4-byte block
        lwl     t0,3(a1)                //
        addu    a0,a0,4                 // advance pointers to next block
        sw      t0,-4(a0)               //
        bne     a0,t2,40b               // if ne, more 4-byte blocks to zero
        addu    a1,a1,4                 //
        .set    reorder

//
// Move 1-byte blocks.
//

50:     addu    t2,a0,a2                // compute ending block address
        beq     zero,a2,70f             // if eq, no bytes to zero

        .set    noreorder
60:     lb      t0,0(a1)                // move 1-byte block
        addu    a0,a0,1                 // advance pointers to next block
        sb      t0,-1(a0)               //
        bne     a0,t2,60b               // if ne, more 1-byte block to zero
        addu    a1,a1,1                 //
        .set    reorder

70:     j       ra                      // return

//
// Move memory backward.
//

MoveBackward:                           //
        addu    a0,a0,a2                // compute ending destination address
        addu    a1,a1,a2                // compute ending source address
        sltu    t0,a2,4                 // check if less than four bytes
        bne     zero,t0,50f             // if ne, less than four bytes to move
        xor     t0,a0,a1                // compare alignment bits
        and     t0,t0,0x3               // isolate alignment comparison
        bne     zero,t0,MoveBackwardUnaligned // if ne, incompatible alignment

//
// Move memory backward aligned.
//

MoveBackwardAligned:                    //
        and     t0,a0,0x3               // isolate residual byte count
        subu    a2,a2,t0                // reduce number of bytes to move
        beq     zero,t0,10f             // if eq, already aligned
        lwl     t1,-1(a1)               // move unaligned bytes
        swl     t1,-1(a0)               //
        subu    a0,a0,t0                // align destination address
        subu    a1,a1,t0                // align source address

//
// Check for 32-byte blocks to move.
//

10:     and     t0,a2,32 - 1            // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        subu    t8,a0,t1                // compute ending block address
        beq     zero,t1,30f             // if eq, no 32-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 32-byte block.
//

#if defined(R4000)

        and     t0,a0,1 << 2            // check if destination quadword aligned
        beq     zero,t0,15f             // if eq, destination quadword aligned
        lw      t0,-4(a1)               // get source longword
        subu    a1,a1,4                 // align source address
        sw      t0,-4(a0)               // store destination longword
        subu    a0,a0,4                 // align destination address
        addu    a2,a2,t1                // recompute byte to move
        subu    a2,a2,4                 // reduce count by 4
        b       10b                     //

//
// The destination is quadword aligned, check the source operand.
//

15:     and     t0,a1,1 << 2            // check if source quadword aligned
        beq     zero,t0,22f             // if eq, source quadword aligned

//
// The source is longword aligned and the destination is quadword aligned.
//

        .set    noreorder
20:     lwc1    f1,-4(a1)               // move 32-byte block
        lwc1    f0,-8(a1)               //
        lwc1    f3,-12(a1)              //
        lwc1    f2,-16(a1)              //
        lwc1    f5,-20(a1)              //
        lwc1    f4,-24(a1)              //
        lwc1    f7,-28(a1)              //
        lwc1    f6,-32(a1)              //
        sdc1    f0,-8(a0)               //
        sdc1    f2,-16(a0)              //
        sdc1    f4,-24(a0)              //
        sdc1    f6,-32(a0)              //
        subu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        subu    a1,a1,32                //
        .set    reorder

        b       30f                     //

//
// Both the source and the destination are quadword aligned.
//

22:     and     t0,t1,1 << 5            // test if even number of 32-byte blocks
        beq     zero,t0,26f             // if eq, even number of 32-byte blocks

//
// Move one 32-byte block quadword aligned.
//

        .set    noreorder
        ldc1    f0,-8(a1)               // move 32-byte block
        ldc1    f2,-16(a1)              //
        ldc1    f4,-24(a1)              //
        ldc1    f6,-32(a1)              //
        sdc1    f0,-8(a0)               //
        sdc1    f2,-16(a0)              //
        sdc1    f4,-24(a0)              //
        sdc1    f6,-32(a0)              //
        subu    a0,a0,32                // advance pointers to next block
        beq     a0,t8,30f               // if eq, end of block
        subu    a1,a1,32                //
        .set    reorder

//
// Move 64-byte blocks quadword aligned.
//

        .set    noreorder
26:     ldc1    f0,-8(a1)               // move 64-byte block
        ldc1    f2,-16(a1)              //
        ldc1    f4,-24(a1)              //
        ldc1    f6,-32(a1)              //
        ldc1    f8,-40(a1)              //
        ldc1    f10,-48(a1)             //
        ldc1    f12,-56(a1)             //
        ldc1    f14,-64(a1)             //
        sdc1    f0,-8(a0)               //
        sdc1    f2,-16(a0)              //
        sdc1    f4,-24(a0)              //
        sdc1    f6,-32(a0)              //
        sdc1    f8,-40(a0)              //
        sdc1    f10,-48(a0)             //
        sdc1    f12,-56(a0)             //
        sdc1    f14,-64(a0)             //
        subu    a0,a0,64                // advance pointers to next block
        bne     a0,t8,26b               // if ne, more 64-byte blocks to zero
        subu    a1,a1,64                //
        .set    reorder

#endif

//
// The source is longword aligned and the destination is longword aligned.
//

#if defined(R3000)

        .set    noreorder
20:     lw      t0,-4(a1)               // move 32-byte block
        lw      t1,-8(a1)               //
        lw      t2,-12(a1)              //
        lw      t3,-16(a1)              //
        lw      t4,-20(a1)              //
        lw      t5,-24(a1)              //
        lw      t6,-28(a1)              //
        lw      t7,-32(a1)              //
        sw      t0,-4(a0)               //
        sw      t1,-8(a0)               //
        sw      t2,-12(a0)              //
        sw      t3,-16(a0)              //
        sw      t4,-20(a0)              //
        sw      t5,-24(a0)              //
        sw      t6,-28(a0)              //
        sw      t7,-32(a0)              //
        subu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        subu    a1,a1,32                //
        .set    reorder

#endif

//
// Check for 4-byte blocks to move.
//

30:     and     t0,a2,4 - 1             // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        subu    t2,a0,t1                // compute ending block address
        beq     zero,t1,50f             // if eq, no 4-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 4-byte block.
//

        .set    noreorder
40:     lw      t0,-4(a1)               // move 4-byte block
        subu    a0,a0,4                 // advance pointers to next block
        sw      t0,0(a0)                //
        bne     a0,t2,40b               // if ne, more 4-byte blocks to zero
        subu    a1,a1,4                 //
        .set    reorder

//
// Move 1-byte blocks.
//

50:     subu    t2,a0,a2                // compute ending block address
        beq     zero,a2,70f             // if eq, no bytes to zero

        .set    noreorder
60:     lb      t0,-1(a1)               // move 1-byte block
        subu    a0,a0,1                 // advance pointers to next block
        sb      t0,0(a0)                //
        bne     a0,t2,60b               // if ne, more 1-byte block to zero
        subu    a1,a1,1                 //
        .set    reorder

70:     j       ra                      // return

//
// Move memory backward unaligned.
//

MoveBackwardUnaligned:                  //
        and     t0,a0,0x3               // isolate residual byte count
        subu    a2,a2,t0                // reduce number of bytes to move
        beq     zero,t0,10f             // if eq, already aligned
        lwl     t1,-1(a1)               // move unaligned bytes
        lwr     t1,-4(a1)               //
        swl     t1,-1(a0)               //
        subu    a0,a0,t0                // align destination address
        subu    a1,a1,t0                // update source address

//
// Check for 32-byte blocks to move.
//

10:     and     t0,a2,32 - 1            // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        subu    t8,a0,t1                // compute ending block address
        beq     zero,t1,30f             // if eq, no 32-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 32-byte block.
//

        .set    noreorder
20:     lwr     t0,-4(a1)               // move 32-byte block
        lwl     t0,-1(a1)               //
        lwr     t1,-8(a1)               //
        lwl     t1,-5(a1)               //
        lwr     t2,-12(a1)              //
        lwl     t2,-9(a1)               //
        lwr     t3,-16(a1)              //
        lwl     t3,-13(a1)              //
        lwr     t4,-20(a1)              //
        lwl     t4,-17(a1)              //
        lwr     t5,-24(a1)              //
        lwl     t5,-21(a1)              //
        lwr     t6,-28(a1)              //
        lwl     t6,-25(a1)              //
        lwr     t7,-32(a1)              //
        lwl     t7,-29(a1)              //
        sw      t0,-4(a0)               //
        sw      t1,-8(a0)               //
        sw      t2,-12(a0)              //
        sw      t3,-16(a0)              //
        sw      t4,-20(a0)              //
        sw      t5,-24(a0)              //
        sw      t6,-28(a0)              //
        sw      t7,-32(a0)              //
        subu    a0,a0,32                // advance pointers to next block
        bne     a0,t8,20b               // if ne, more 32-byte blocks to zero
        subu    a1,a1,32                //
        .set    reorder

//
// Check for 4-byte blocks to move.
//

30:     and     t0,a2,4 - 1             // isolate residual bytes
        subu    t1,a2,t0                // subtract out residual bytes
        subu    t2,a0,t1                // compute ending block address
        beq     zero,t1,50f             // if eq, no 4-byte block to zero
        move    a2,t0                   // set residual number of bytes

//
// Move 4-byte block.
//

        .set    noreorder
40:     lwr     t0,-4(a1)               // move 4-byte block
        lwl     t0,-1(a1)               //
        subu    a0,a0,4                 // advance pointers to next block
        sw      t0,0(a0)                //
        bne     a0,t2,40b               // if ne, more 4-byte blocks to zero
        subu    a1,a1,4                 //
        .set    reorder

//
// Move 1-byte blocks.
//

50:     subu    t2,a0,a2                // compute ending block address
        beq     zero,a2,70f             // if eq, no bytes to zero

        .set    noreorder
60:     lb      t0,-1(a1)               // move 1-byte block
        subu    a0,a0,1                 // advance pointers to next block
        sb      t0,0(a0)                //
        bne     a0,t2,60b               // if ne, more 1-byte block to zero
        subu    a1,a1,1                 //
        .set    reorder

70:     j       ra                      // return

        .end    memcpy

        SBTTL("Fill Memory")
//++
//
// VOID
// RtlFillMemory (
//    IN PVOID Destination,
//    IN ULONG Length,
//    IN UCHAR Fill
//    )
//
// Routine Description:
//
//    This function fills memory by first aligning the destination address to
//    a longword boundary, and then filling 32-byte blocks, followed by 4-byte
//    blocks, followed by any remaining bytes.
//
// Arguments:
//
//    Destination (a0) - Supplies a pointer to the memory to fill.
//
//    Length (a1) - Supplies the length, in bytes, of the memory to be filled.
//
//    Fill (a2) - Supplies the fill byte.
//
//    N.B. The alternate entry memset expects the length and fill arguments
//         to be reversed.
//
// Return Value:
//
//    None.
//
//--

        LEAF_ENTRY(memset)

        move    a3,a1                   // swap length and fill arguments
        move    a1,a2                   //
        move    a2,a3                   //
        move    v0,a0                   // return destination

        and     a2,a2,0xff              // clear excess bits
        sll     t0,a2,8                 // duplicate fill byte
        or      a2,a2,t0                // generate fill word
        sll     t0,a2,16                // duplicate fill word
        or      a2,a2,t0                // generate fill longword

//
// Fill memory with the pattern specified in register a2.
//

#if DBG

        mtc1    a2,f0                   // set pattern to store
        mtc1    a2,f1                   //

#endif

        subu    t0,zero,a0              // compute bytes until aligned
        and     t0,t0,0x3               // isolate residual byte count
        subu    t1,a1,t0                // reduce number of bytes to fill
        blez    t1,60f                  // if lez, less than 4 bytes to fill
        move    a1,t1                   // set number of bytes to fill
        beq     zero,t0,10f             // if eq, already aligned
        swr     a2,0(a0)                // fill unaligned bytes
        addu    a0,a0,t0                // align destination address

//
// Check for 32-byte blocks to fill.
//

10:     and     t0,a1,32 - 1            // isolate residual bytes
        subu    t1,a1,t0                // subtract out residual bytes
        addu    t2,a0,t1                // compute ending block address
        beq     zero,t1,40f             // if eq, no 32-byte blocks to fill
        move    a1,t0                   // set residual number of bytes

//
// Fill 32-byte blocks.
//

#if defined(R4000)

        and     t0,a0,1 << 2            // check if destintion quadword aligned
        beq     zero,t0,20f             // if eq, yes
        sw      a2,0(a0)                // store destination longword
        addu    a0,a0,4                 // align destination address
        addu    a1,a1,t1                // recompute bytes to fill
        subu    a1,a1,4                 // reduce count by 4
        b       10b                     //

//
// The destination is quadword aligned.
//

20:     mtc1    a2,f0                   // set pattern value
        mtc1    a2,f1                   //
        and     t0,t1,1 << 5            // test if even number of 32-byte blocks
        beq     zero,t0,30f             // if eq, even number of 32-byte blocks

//
// Fill one 32-byte block.
//

        .set    noreorder
        sdc1    f0,0(a0)                // fill 32-byte block
        sdc1    f0,8(a0)                //
        sdc1    f0,16(a0)               //
        addu    a0,a0,32                // advance pointer to next block
        beq     a0,t2,40f               // if ne, no 64-byte blocks to fill
        sdc1    f0,-8(a0)               //
        .set    reorder

//
// Fill 64-byte block.
//

        .set    noreorder
30:     sdc1    f0,0(a0)                // fill 32-byte block
        sdc1    f0,8(a0)                //
        sdc1    f0,16(a0)               //
        sdc1    f0,24(a0)               //
        sdc1    f0,32(a0)               //
        sdc1    f0,40(a0)               //
        sdc1    f0,48(a0)               //
        addu    a0,a0,64                // advance pointer to next block
        bne     a0,t2,30b               // if ne, more 32-byte blocks to fill
        sdc1    f0,-8(a0)               //
        .set    reorder

#endif

//
// Fill 32-byte blocks.
//

#if defined(R3000)

        .set    noreorder
20:     sw      a2,0(a0)                // fill 32-byte block
        sw      a2,4(a0)                //
        sw      a2,8(a0)                //
        sw      a2,12(a0)               //
        addu    a0,a0,32                // advance pointer to next block
        sw      a2,-4(a0)               //
        sw      a2,-8(a0)               //
        sw      a2,-12(a0)              //
        bne     a0,t2,20b               // if ne, more 32-byte blocks to fill
        sw      a2,-16(a0)              //
        .set    reorder

#endif

//
// Check for 4-byte blocks to fill.
//

40:     and     t0,a1,4 - 1             // isolate residual bytes
        subu    t1,a1,t0                // subtract out residual bytes
        addu    t2,a0,t1                // compute ending block address
        beq     zero,t1,60f             // if eq, no 4-byte block to fill
        move    a1,t0                   // set residual number of bytes

//
// Fill 4-byte blocks.
//

        .set    noreorder
50:     addu    a0,a0,4                 // advance pointer to next block
        bne     a0,t2,50b               // if ne, more 4-byte blocks to fill
        sw      a2,-4(a0)               // fill 4-byte block
        .set    reorder

//
// Check for 1-byte blocks to fill.
//

60:     addu    t2,a0,a1                // compute ending block address
        beq     zero,a1,80f             // if eq, no bytes to fill

//
// Fill 1-byte blocks.
//

        .set    noreorder
70:     addu    a0,a0,1                 // advance pointer to next block
        bne     a0,t2,70b               // if ne, more 1-byte block to fill
        sb      a2,-1(a0)               // fill 1-byte block
        .set    reorder

#if DBG

80:     mfc1    t0,f0                   // get fill pattern
        mfc1    t1,f1                   //
        bne     t0,a2,90f               // if ne, pattern altered
        bne     t1,a2,90f               // if ne, pattern altered
        j       ra                      // return

90:     break   KERNEL_BREAKPOINT       //

#else

80:     j       ra                      // return

#endif

        .end    memset
