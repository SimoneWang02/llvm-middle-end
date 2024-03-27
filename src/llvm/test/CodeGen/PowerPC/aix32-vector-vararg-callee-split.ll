; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -verify-machineinstrs -stop-before=ppc-vsx-copy -vec-extabi \
; RUN:     -mcpu=pwr7  -mtriple powerpc-ibm-aix-xcoff < %s | \
; RUN: FileCheck %s

;; Testing a variadic callee where a vector argument passed through ellipsis
;; is passed partially in registers and on the stack. The 3 fixed double
;; arguments shadow r3-r8, and a vector int <4 x i32> is passed in R9/R10 and
;; on the stack starting at the shadow of R9.
define <4 x i32> @split_spill(double %d1, double %d2, double %d3, ...) {
  ; CHECK-LABEL: name: split_spill
  ; CHECK: bb.0.entry:
  ; CHECK:   liveins: $r9, $r10
  ; CHECK:   [[COPY:%[0-9]+]]:gprc = COPY $r10
  ; CHECK:   [[COPY1:%[0-9]+]]:gprc = COPY $r9
  ; CHECK:   STW [[COPY1]], 0, %fixed-stack.0 :: (store (s32) into %fixed-stack.0, align 16)
  ; CHECK:   STW [[COPY]], 4, %fixed-stack.0 :: (store (s32) into %fixed-stack.0 + 4)
  ; CHECK:   LIFETIME_START %stack.0.arg_list
  ; CHECK:   [[ADDI:%[0-9]+]]:gprc = ADDI %fixed-stack.0, 0
  ; CHECK:   [[LXVW4X:%[0-9]+]]:vsrc = LXVW4X $zero, killed [[ADDI]] :: (load (s128) from %ir.argp.cur.aligned)
  ; CHECK:   LIFETIME_END %stack.0.arg_list
  ; CHECK:   $v2 = COPY [[LXVW4X]]
  ; CHECK:   BLR implicit $lr, implicit $rm, implicit $v2
entry:
  %arg_list = alloca ptr, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %arg_list)
  call void @llvm.va_start(ptr nonnull %arg_list)
  %argp.cur = load ptr, ptr %arg_list, align 4
  %0 = ptrtoint ptr %argp.cur to i32
  %1 = add i32 %0, 15
  %2 = and i32 %1, -16
  %argp.cur.aligned = inttoptr i32 %2 to ptr
  %argp.next = getelementptr inbounds i8, ptr %argp.cur.aligned, i32 16
  store ptr %argp.next, ptr %arg_list, align 4
  %3 = inttoptr i32 %2 to ptr
  %4 = load <4 x i32>, ptr %3, align 16
  call void @llvm.va_end(ptr nonnull %arg_list)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %arg_list)
  ret <4 x i32> %4
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.va_start(ptr)

declare void @llvm.va_end(ptr)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)