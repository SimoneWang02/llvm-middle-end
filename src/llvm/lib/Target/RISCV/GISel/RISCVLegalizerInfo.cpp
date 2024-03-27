//===-- RISCVLegalizerInfo.cpp ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// This file implements the targeting of the Machinelegalizer class for RISC-V.
/// \todo This should be generated by TableGen.
//===----------------------------------------------------------------------===//

#include "RISCVLegalizerInfo.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/TargetOpcodes.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Type.h"

using namespace llvm;

RISCVLegalizerInfo::RISCVLegalizerInfo(const RISCVSubtarget &ST) {
  const unsigned XLen = ST.getXLen();
  const LLT XLenLLT = LLT::scalar(XLen);

  using namespace TargetOpcode;

  getActionDefinitionsBuilder({G_ADD, G_SUB, G_AND, G_OR, G_XOR})
      .legalFor({XLenLLT})
      .clampScalar(0, XLenLLT, XLenLLT);

  getLegacyLegalizerInfo().computeTables();
}