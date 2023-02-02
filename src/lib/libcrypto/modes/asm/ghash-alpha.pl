#!/usr/bin/env perl
#
# ====================================================================
# Written by Andy Polyakov <appro@openssl.org> for the OpenSSL
# project. The module is, however, dual licensed under OpenSSL and
# CRYPTOGAMS licenses depending on where you obtain it. For further
# details see http://www.openssl.org/~appro/cryptogams/.
# ====================================================================
#
# March 2010
#
# The module implements "4-bit" GCM GHASH function and underlying
# single multiplication operation in GF(2^128). "4-bit" means that it
# uses 256 bytes per-key table [+128 bytes shared table]. Even though
# loops are aggressively modulo-scheduled in respect to references to
# Htbl and Z.hi updates for 8 cycles per byte, measured performance is
# ~12 cycles per processed byte on 21264 CPU. It seems to be a dynamic
# scheduling "glitch," because uprofile(1) indicates uniform sample
# distribution, as if all instruction bundles execute in 1.5 cycles.
# Meaning that it could have been even faster, yet 12 cycles is ~60%
# better than gcc-generated code and ~80% than code generated by vendor
# compiler.

$cnt="v0";	# $0
$t0="t0";
$t1="t1";
$t2="t2";
$Thi0="t3";	# $4
$Tlo0="t4";
$Thi1="t5";
$Tlo1="t6";
$rem="t7";	# $8
#################
$Xi="a0";	# $16, input argument block
$Htbl="a1";
$inp="a2";
$len="a3";
$nlo="a4";	# $20
$nhi="a5";
$Zhi="t8";
$Zlo="t9";
$Xhi="t10";	# $24
$Xlo="t11";
$remp="t12";
$rem_4bit="AT";	# $28

{ my $N;
  sub loop() {

	$N++;
$code.=<<___;
.align	4
	extbl	$Xlo,7,$nlo
	and	$nlo,0xf0,$nhi
	sll	$nlo,4,$nlo
	and	$nlo,0xf0,$nlo

	addq	$nlo,$Htbl,$nlo
	ldq	$Zlo,8($nlo)
	addq	$nhi,$Htbl,$nhi
	ldq	$Zhi,0($nlo)

	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	lda	$cnt,6(zero)
	extbl	$Xlo,6,$nlo

	ldq	$Tlo1,8($nhi)
	s8addq	$remp,$rem_4bit,$remp
	ldq	$Thi1,0($nhi)
	srl	$Zlo,4,$Zlo

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$t0,$Zlo,$Zlo
	and	$nlo,0xf0,$nhi

	xor	$Tlo1,$Zlo,$Zlo
	sll	$nlo,4,$nlo
	xor	$Thi1,$Zhi,$Zhi
	and	$nlo,0xf0,$nlo

	addq	$nlo,$Htbl,$nlo
	ldq	$Tlo0,8($nlo)
	addq	$nhi,$Htbl,$nhi
	ldq	$Thi0,0($nlo)

.Looplo$N:
	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	subq	$cnt,1,$cnt
	srl	$Zlo,4,$Zlo

	ldq	$Tlo1,8($nhi)
	xor	$rem,$Zhi,$Zhi
	ldq	$Thi1,0($nhi)
	s8addq	$remp,$rem_4bit,$remp

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$t0,$Zlo,$Zlo
	extbl	$Xlo,$cnt,$nlo

	and	$nlo,0xf0,$nhi
	xor	$Thi0,$Zhi,$Zhi
	xor	$Tlo0,$Zlo,$Zlo
	sll	$nlo,4,$nlo


	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	and	$nlo,0xf0,$nlo
	srl	$Zlo,4,$Zlo

	s8addq	$remp,$rem_4bit,$remp
	xor	$rem,$Zhi,$Zhi
	addq	$nlo,$Htbl,$nlo
	addq	$nhi,$Htbl,$nhi

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	ldq	$Tlo0,8($nlo)
	xor	$t0,$Zlo,$Zlo

	xor	$Tlo1,$Zlo,$Zlo
	xor	$Thi1,$Zhi,$Zhi
	ldq	$Thi0,0($nlo)
	bne	$cnt,.Looplo$N


	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	lda	$cnt,7(zero)
	srl	$Zlo,4,$Zlo

	ldq	$Tlo1,8($nhi)
	xor	$rem,$Zhi,$Zhi
	ldq	$Thi1,0($nhi)
	s8addq	$remp,$rem_4bit,$remp

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$t0,$Zlo,$Zlo
	extbl	$Xhi,$cnt,$nlo

	and	$nlo,0xf0,$nhi
	xor	$Thi0,$Zhi,$Zhi
	xor	$Tlo0,$Zlo,$Zlo
	sll	$nlo,4,$nlo

	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	and	$nlo,0xf0,$nlo
	srl	$Zlo,4,$Zlo

	s8addq	$remp,$rem_4bit,$remp
	xor	$rem,$Zhi,$Zhi
	addq	$nlo,$Htbl,$nlo
	addq	$nhi,$Htbl,$nhi

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	ldq	$Tlo0,8($nlo)
	xor	$t0,$Zlo,$Zlo

	xor	$Tlo1,$Zlo,$Zlo
	xor	$Thi1,$Zhi,$Zhi
	ldq	$Thi0,0($nlo)
	unop


.Loophi$N:
	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	subq	$cnt,1,$cnt
	srl	$Zlo,4,$Zlo

	ldq	$Tlo1,8($nhi)
	xor	$rem,$Zhi,$Zhi
	ldq	$Thi1,0($nhi)
	s8addq	$remp,$rem_4bit,$remp

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$t0,$Zlo,$Zlo
	extbl	$Xhi,$cnt,$nlo

	and	$nlo,0xf0,$nhi
	xor	$Thi0,$Zhi,$Zhi
	xor	$Tlo0,$Zlo,$Zlo
	sll	$nlo,4,$nlo


	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	and	$nlo,0xf0,$nlo
	srl	$Zlo,4,$Zlo

	s8addq	$remp,$rem_4bit,$remp
	xor	$rem,$Zhi,$Zhi
	addq	$nlo,$Htbl,$nlo
	addq	$nhi,$Htbl,$nhi

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	ldq	$Tlo0,8($nlo)
	xor	$t0,$Zlo,$Zlo

	xor	$Tlo1,$Zlo,$Zlo
	xor	$Thi1,$Zhi,$Zhi
	ldq	$Thi0,0($nlo)
	bne	$cnt,.Loophi$N


	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	srl	$Zlo,4,$Zlo

	ldq	$Tlo1,8($nhi)
	xor	$rem,$Zhi,$Zhi
	ldq	$Thi1,0($nhi)
	s8addq	$remp,$rem_4bit,$remp

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$t0,$Zlo,$Zlo

	xor	$Tlo0,$Zlo,$Zlo
	xor	$Thi0,$Zhi,$Zhi

	and	$Zlo,0x0f,$remp
	sll	$Zhi,60,$t0
	srl	$Zlo,4,$Zlo

	s8addq	$remp,$rem_4bit,$remp
	xor	$rem,$Zhi,$Zhi

	ldq	$rem,0($remp)
	srl	$Zhi,4,$Zhi
	xor	$Tlo1,$Zlo,$Zlo
	xor	$Thi1,$Zhi,$Zhi
	xor	$t0,$Zlo,$Zlo
	xor	$rem,$Zhi,$Zhi
___
}}

$code=<<___;
#include <machine/asm.h>

.text

.set	noat
.set	noreorder
.globl	gcm_gmult_4bit
.align	4
.ent	gcm_gmult_4bit
gcm_gmult_4bit:
	.frame	sp,0,ra
	.prologue 0

	ldq	$Xlo,8($Xi)
	ldq	$Xhi,0($Xi)

	lda	$rem_4bit,rem_4bit
___

	&loop();

$code.=<<___;
	srl	$Zlo,24,$t0	# byte swap
	srl	$Zlo,8,$t1

	sll	$Zlo,8,$t2
	sll	$Zlo,24,$Zlo
	zapnot	$t0,0x11,$t0
	zapnot	$t1,0x22,$t1

	zapnot	$Zlo,0x88,$Zlo
	or	$t0,$t1,$t0
	zapnot	$t2,0x44,$t2

	or	$Zlo,$t0,$Zlo
	srl	$Zhi,24,$t0
	srl	$Zhi,8,$t1

	or	$Zlo,$t2,$Zlo
	sll	$Zhi,8,$t2
	sll	$Zhi,24,$Zhi

	srl	$Zlo,32,$Xlo
	sll	$Zlo,32,$Zlo

	zapnot	$t0,0x11,$t0
	zapnot	$t1,0x22,$t1
	or	$Zlo,$Xlo,$Xlo

	zapnot	$Zhi,0x88,$Zhi
	or	$t0,$t1,$t0
	zapnot	$t2,0x44,$t2

	or	$Zhi,$t0,$Zhi
	or	$Zhi,$t2,$Zhi

	srl	$Zhi,32,$Xhi
	sll	$Zhi,32,$Zhi

	or	$Zhi,$Xhi,$Xhi
	stq	$Xlo,8($Xi)
	stq	$Xhi,0($Xi)

	ret	(ra)
.end	gcm_gmult_4bit
___

$inhi="s0";
$inlo="s1";

$code.=<<___;
.globl	gcm_ghash_4bit
.align	4
.ent	gcm_ghash_4bit
gcm_ghash_4bit:
	lda	sp,-32(sp)
	stq	ra,0(sp)
	stq	s0,8(sp)
	stq	s1,16(sp)
	.mask	0x04000600,-32
	.frame	sp,32,ra
	.prologue 0

	ldq_u	$inhi,0($inp)
	ldq_u	$Thi0,7($inp)
	ldq_u	$inlo,8($inp)
	ldq_u	$Tlo0,15($inp)
	ldq	$Xhi,0($Xi)
	ldq	$Xlo,8($Xi)

	lda	$rem_4bit,rem_4bit

.Louter:
	extql	$inhi,$inp,$inhi
	extqh	$Thi0,$inp,$Thi0
	or	$inhi,$Thi0,$inhi
	lda	$inp,16($inp)

	extql	$inlo,$inp,$inlo
	extqh	$Tlo0,$inp,$Tlo0
	or	$inlo,$Tlo0,$inlo
	subq	$len,16,$len

	xor	$Xlo,$inlo,$Xlo
	xor	$Xhi,$inhi,$Xhi
___

	&loop();

$code.=<<___;
	srl	$Zlo,24,$t0	# byte swap
	srl	$Zlo,8,$t1

	sll	$Zlo,8,$t2
	sll	$Zlo,24,$Zlo
	zapnot	$t0,0x11,$t0
	zapnot	$t1,0x22,$t1

	zapnot	$Zlo,0x88,$Zlo
	or	$t0,$t1,$t0
	zapnot	$t2,0x44,$t2

	or	$Zlo,$t0,$Zlo
	srl	$Zhi,24,$t0
	srl	$Zhi,8,$t1

	or	$Zlo,$t2,$Zlo
	sll	$Zhi,8,$t2
	sll	$Zhi,24,$Zhi

	srl	$Zlo,32,$Xlo
	sll	$Zlo,32,$Zlo
	beq	$len,.Ldone

	zapnot	$t0,0x11,$t0
	zapnot	$t1,0x22,$t1
	or	$Zlo,$Xlo,$Xlo
	ldq_u	$inhi,0($inp)

	zapnot	$Zhi,0x88,$Zhi
	or	$t0,$t1,$t0
	zapnot	$t2,0x44,$t2
	ldq_u	$Thi0,7($inp)

	or	$Zhi,$t0,$Zhi
	or	$Zhi,$t2,$Zhi
	ldq_u	$inlo,8($inp)
	ldq_u	$Tlo0,15($inp)

	srl	$Zhi,32,$Xhi
	sll	$Zhi,32,$Zhi

	or	$Zhi,$Xhi,$Xhi
	br	zero,.Louter

.Ldone:
	zapnot	$t0,0x11,$t0
	zapnot	$t1,0x22,$t1
	or	$Zlo,$Xlo,$Xlo

	zapnot	$Zhi,0x88,$Zhi
	or	$t0,$t1,$t0
	zapnot	$t2,0x44,$t2

	or	$Zhi,$t0,$Zhi
	or	$Zhi,$t2,$Zhi

	srl	$Zhi,32,$Xhi
	sll	$Zhi,32,$Zhi

	or	$Zhi,$Xhi,$Xhi

	stq	$Xlo,8($Xi)
	stq	$Xhi,0($Xi)

	.set	noreorder
	/*ldq	ra,0(sp)*/
	ldq	s0,8(sp)
	ldq	s1,16(sp)
	lda	sp,32(sp)
	ret	(ra)
.end	gcm_ghash_4bit

	.section .rodata
	.align	4
rem_4bit:
	.long	0,0x0000<<16, 0,0x1C20<<16, 0,0x3840<<16, 0,0x2460<<16
	.long	0,0x7080<<16, 0,0x6CA0<<16, 0,0x48C0<<16, 0,0x54E0<<16
	.long	0,0xE100<<16, 0,0xFD20<<16, 0,0xD940<<16, 0,0xC560<<16
	.long	0,0x9180<<16, 0,0x8DA0<<16, 0,0xA9C0<<16, 0,0xB5E0<<16
	.previous

___
$output=shift and open STDOUT,">$output";
print $code;
close STDOUT;

