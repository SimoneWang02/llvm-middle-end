; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -passes=instsimplify < %s | FileCheck %s

declare void @bar(ptr %a, ptr nonnull noundef %b)
declare void @bar_without_noundef(ptr %a, ptr nonnull %b)

; 'y' must be nonnull.

define i1 @caller1(ptr %x, ptr %y) {
; CHECK-LABEL: @caller1(
; CHECK-NEXT:    call void @bar(ptr [[X:%.*]], ptr [[Y:%.*]])
; CHECK-NEXT:    ret i1 false
;
  call void @bar(ptr %x, ptr %y)
  %null_check = icmp eq ptr %y, null
  ret i1 %null_check
}

; Don't know anything about 'y'.

define i1 @caller1_maybepoison(ptr %x, ptr %y) {
; CHECK-LABEL: @caller1_maybepoison(
; CHECK-NEXT:    call void @bar_without_noundef(ptr [[X:%.*]], ptr [[Y:%.*]])
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp eq ptr [[Y]], null
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
;
  call void @bar_without_noundef(ptr %x, ptr %y)
  %null_check = icmp eq ptr %y, null
  ret i1 %null_check
}

; Don't know anything about 'y'.

define i1 @caller2(ptr %x, ptr %y) {
; CHECK-LABEL: @caller2(
; CHECK-NEXT:    call void @bar(ptr [[Y:%.*]], ptr [[X:%.*]])
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp eq ptr [[Y]], null
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
;
  call void @bar(ptr %y, ptr %x)
  %null_check = icmp eq ptr %y, null
  ret i1 %null_check
}

; 'y' must be nonnull.

define i1 @caller3(ptr %x, ptr %y) {
; CHECK-LABEL: @caller3(
; CHECK-NEXT:    call void @bar(ptr [[X:%.*]], ptr [[Y:%.*]])
; CHECK-NEXT:    ret i1 true
;
  call void @bar(ptr %x, ptr %y)
  %null_check = icmp ne ptr %y, null
  ret i1 %null_check
}

; FIXME: The call is guaranteed to execute, so 'y' must be nonnull throughout.

define i1 @caller4(ptr %x, ptr %y) {
; CHECK-LABEL: @caller4(
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp ne ptr [[Y:%.*]], null
; CHECK-NEXT:    call void @bar(ptr [[X:%.*]], ptr [[Y]])
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
;
  %null_check = icmp ne ptr %y, null
  call void @bar(ptr %x, ptr %y)
  ret i1 %null_check
}

; The call to bar() does not dominate the null check, so no change.

define i1 @caller5(ptr %x, ptr %y) {
; CHECK-LABEL: @caller5(
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp eq ptr [[Y:%.*]], null
; CHECK-NEXT:    br i1 [[NULL_CHECK]], label [[T:%.*]], label [[F:%.*]]
; CHECK:       t:
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
; CHECK:       f:
; CHECK-NEXT:    call void @bar(ptr [[X:%.*]], ptr [[Y]])
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
;
  %null_check = icmp eq ptr %y, null
  br i1 %null_check, label %t, label %f
t:
  ret i1 %null_check
f:
  call void @bar(ptr %x, ptr %y)
  ret i1 %null_check
}

; Make sure that an invoke works similarly to a call.

declare i32 @esfp(...)

define i1 @caller6(ptr %x, ptr %y) personality ptr @esfp{
; CHECK-LABEL: @caller6(
; CHECK-NEXT:    invoke void @bar(ptr [[X:%.*]], ptr nonnull [[Y:%.*]])
; CHECK-NEXT:    to label [[CONT:%.*]] unwind label [[EXC:%.*]]
; CHECK:       cont:
; CHECK-NEXT:    ret i1 false
; CHECK:       exc:
; CHECK-NEXT:    [[LP:%.*]] = landingpad { ptr, i32 }
; CHECK-NEXT:    filter [0 x ptr] zeroinitializer
; CHECK-NEXT:    unreachable
;
  invoke void @bar(ptr %x, ptr nonnull %y)
  to label %cont unwind label %exc

cont:
  %null_check = icmp eq ptr %y, null
  ret i1 %null_check

exc:
  %lp = landingpad { ptr, i32 }
  filter [0 x ptr] zeroinitializer
  unreachable
}

declare ptr @returningPtr(ptr returned %p)

define i1 @nonnullReturnTest(ptr nonnull %x) {
; CHECK-LABEL: @nonnullReturnTest(
; CHECK-NEXT:    [[X2:%.*]] = call ptr @returningPtr(ptr [[X:%.*]])
; CHECK-NEXT:    ret i1 false
;
  %x2 = call ptr @returningPtr(ptr %x)
  %null_check = icmp eq ptr %x2, null
  ret i1 %null_check
}

define i1 @unknownReturnTest(ptr %x) {
; CHECK-LABEL: @unknownReturnTest(
; CHECK-NEXT:    [[X2:%.*]] = call ptr @returningPtr(ptr [[X:%.*]])
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp eq ptr [[X2]], null
; CHECK-NEXT:    ret i1 [[NULL_CHECK]]
;
  %x2 = call ptr @returningPtr(ptr %x)
  %null_check = icmp eq ptr %x2, null
  ret i1 %null_check
}

; Make sure that if load/store happened, the pointer is nonnull.

define i32 @test_null_after_store(ptr %0) {
; CHECK-LABEL: @test_null_after_store(
; CHECK-NEXT:    store i32 123, ptr [[TMP0:%.*]], align 4
; CHECK-NEXT:    ret i32 2
;
  store i32 123, ptr %0, align 4
  %2 = icmp eq ptr %0, null
  %3 = select i1 %2, i32 1, i32 2
  ret i32 %3
}

define i32 @test_null_after_load(ptr %0) {
; CHECK-LABEL: @test_null_after_load(
; CHECK-NEXT:    ret i32 1
;
  %2 = load i32, ptr %0, align 4
  %3 = icmp eq ptr %0, null
  %4 = select i1 %3, i32 %2, i32 1
  ret i32 %4
}

; Make sure that different address space does not affect null pointer check.

define i32 @test_null_after_store_addrspace(ptr addrspace(1) %0) {
; CHECK-LABEL: @test_null_after_store_addrspace(
; CHECK-NEXT:    store i32 123, ptr addrspace(1) [[TMP0:%.*]], align 4
; CHECK-NEXT:    [[TMP2:%.*]] = icmp eq ptr addrspace(1) [[TMP0]], null
; CHECK-NEXT:    [[TMP3:%.*]] = select i1 [[TMP2]], i32 1, i32 2
; CHECK-NEXT:    ret i32 [[TMP3]]
;
  store i32 123, ptr addrspace(1) %0, align 4
  %2 = icmp eq ptr addrspace(1) %0, null
  %3 = select i1 %2, i32 1, i32 2
  ret i32 %3
}

define i32 @test_null_after_load_addrspace(ptr addrspace(1) %0) {
; CHECK-LABEL: @test_null_after_load_addrspace(
; CHECK-NEXT:    [[TMP2:%.*]] = load i32, ptr addrspace(1) [[TMP0:%.*]], align 4
; CHECK-NEXT:    [[TMP3:%.*]] = icmp eq ptr addrspace(1) [[TMP0]], null
; CHECK-NEXT:    [[TMP4:%.*]] = select i1 [[TMP3]], i32 [[TMP2]], i32 1
; CHECK-NEXT:    ret i32 [[TMP4]]
;
  %2 = load i32, ptr addrspace(1) %0, align 4
  %3 = icmp eq ptr addrspace(1) %0, null
  %4 = select i1 %3, i32 %2, i32 1
  ret i32 %4
}

; Make sure if store happened after the check, nullptr check is not removed.

declare ptr @func(i64)

define ptr @test_load_store_after_check(ptr %0) {
; CHECK-LABEL: @test_load_store_after_check(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP1:%.*]] = call ptr @func(i64 0)
; CHECK-NEXT:    [[NULL_CHECK:%.*]] = icmp eq ptr [[TMP1]], null
; CHECK-NEXT:    br i1 [[NULL_CHECK]], label [[RETURN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.end:
; CHECK-NEXT:    store i8 7, ptr [[TMP1]], align 1
; CHECK-NEXT:    br label [[RETURN]]
; CHECK:       return:
; CHECK-NEXT:    [[RETVAL_0:%.*]] = phi ptr [ [[TMP1]], [[IF_END]] ], [ null, [[ENTRY:%.*]] ]
; CHECK-NEXT:    ret ptr [[RETVAL_0]]
;
entry:
  %1 = call ptr @func(i64 0)
  %null_check = icmp eq ptr %1, null
  br i1 %null_check, label %return, label %if.end

if.end:
  store i8 7, ptr %1
  br label %return

return:
  %retval.0 = phi ptr [ %1, %if.end ], [ null, %entry ]
  ret ptr %retval.0
}