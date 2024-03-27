; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc < %s -mtriple=aarch64-none-linux-gnu -mattr=+neon | FileCheck %s --check-prefix=CHECK

declare <4 x half> @llvm.maximum.v4f16(<4 x half>, <4 x half>)

declare <2 x fp128> @llvm.maximum.v2f128(<2 x fp128>, <2 x fp128>)

; Fixes PR63267
define <4 x half> @fmaximum_v4f16(<4 x half> %x, <4 x half> %y) {
; CHECK-LABEL: fmaximum_v4f16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    // kill: def $d1 killed $d1 def $q1
; CHECK-NEXT:    // kill: def $d0 killed $d0 def $q0
; CHECK-NEXT:    mov h2, v1.h[1]
; CHECK-NEXT:    mov h3, v0.h[1]
; CHECK-NEXT:    fcvt s4, h1
; CHECK-NEXT:    fcvt s5, h0
; CHECK-NEXT:    mov h6, v1.h[2]
; CHECK-NEXT:    mov h7, v0.h[2]
; CHECK-NEXT:    mov h1, v1.h[3]
; CHECK-NEXT:    fcvt s2, h2
; CHECK-NEXT:    fcvt s3, h3
; CHECK-NEXT:    fmax s4, s5, s4
; CHECK-NEXT:    fcvt s5, h7
; CHECK-NEXT:    fcvt s1, h1
; CHECK-NEXT:    fmax s2, s3, s2
; CHECK-NEXT:    fcvt s3, h6
; CHECK-NEXT:    mov h6, v0.h[3]
; CHECK-NEXT:    fcvt h0, s4
; CHECK-NEXT:    fcvt h2, s2
; CHECK-NEXT:    fmax s3, s5, s3
; CHECK-NEXT:    fcvt s4, h6
; CHECK-NEXT:    mov v0.h[1], v2.h[0]
; CHECK-NEXT:    fcvt h2, s3
; CHECK-NEXT:    fmax s1, s4, s1
; CHECK-NEXT:    mov v0.h[2], v2.h[0]
; CHECK-NEXT:    fcvt h1, s1
; CHECK-NEXT:    mov v0.h[3], v1.h[0]
; CHECK-NEXT:    // kill: def $d0 killed $d0 killed $q0
; CHECK-NEXT:    ret
  %r = call <4 x half> @llvm.maximum.v4f16(<4 x half> %x, <4 x half> %y)
  ret <4 x half> %r
}