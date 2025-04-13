
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ae70713          	addi	a4,a4,-1874 # 80008900 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	ccc78793          	addi	a5,a5,-820 # 80005d30 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc88f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e2e78793          	addi	a5,a5,-466 # 80000edc <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3e8080e7          	jalr	1000(ra) # 80002514 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8b450513          	addi	a0,a0,-1868 # 80010a40 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a9e080e7          	jalr	-1378(ra) # 80000c32 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8a448493          	addi	s1,s1,-1884 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	93290913          	addi	s2,s2,-1742 # 80010ad8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	84a080e7          	jalr	-1974(ra) # 80001a0e <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	192080e7          	jalr	402(ra) # 8000235e <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	edc080e7          	jalr	-292(ra) # 800020b6 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	2a8080e7          	jalr	680(ra) # 800024be <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	81650513          	addi	a0,a0,-2026 # 80010a40 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	ab4080e7          	jalr	-1356(ra) # 80000ce6 <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	80050513          	addi	a0,a0,-2048 # 80010a40 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a9e080e7          	jalr	-1378(ra) # 80000ce6 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	86f72023          	sw	a5,-1952(a4) # 80010ad8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	76e50513          	addi	a0,a0,1902 # 80010a40 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	958080e7          	jalr	-1704(ra) # 80000c32 <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	272080e7          	jalr	626(ra) # 8000256a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	74050513          	addi	a0,a0,1856 # 80010a40 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	9de080e7          	jalr	-1570(ra) # 80000ce6 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	71c70713          	addi	a4,a4,1820 # 80010a40 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	6f278793          	addi	a5,a5,1778 # 80010a40 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	75c7a783          	lw	a5,1884(a5) # 80010ad8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6b070713          	addi	a4,a4,1712 # 80010a40 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6a048493          	addi	s1,s1,1696 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	66470713          	addi	a4,a4,1636 # 80010a40 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6ef72723          	sw	a5,1774(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	62878793          	addi	a5,a5,1576 # 80010a40 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6ac7a023          	sw	a2,1696(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	69450513          	addi	a0,a0,1684 # 80010ad8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	cce080e7          	jalr	-818(ra) # 8000211a <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5da50513          	addi	a0,a0,1498 # 80010a40 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	734080e7          	jalr	1844(ra) # 80000ba2 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	95a78793          	addi	a5,a5,-1702 # 80020dd8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5a07a823          	sw	zero,1456(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	32f72e23          	sw	a5,828(a4) # 800088c0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	540dad83          	lw	s11,1344(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4ea50513          	addi	a0,a0,1258 # 80010ae8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	62c080e7          	jalr	1580(ra) # 80000c32 <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	38650513          	addi	a0,a0,902 # 80010ae8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	57c080e7          	jalr	1404(ra) # 80000ce6 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	36a48493          	addi	s1,s1,874 # 80010ae8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	412080e7          	jalr	1042(ra) # 80000ba2 <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	32a50513          	addi	a0,a0,810 # 80010b08 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	3bc080e7          	jalr	956(ra) # 80000ba2 <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	3e4080e7          	jalr	996(ra) # 80000be6 <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0b67a783          	lw	a5,182(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	452080e7          	jalr	1106(ra) # 80000c86 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	08273703          	ld	a4,130(a4) # 800088c8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0827b783          	ld	a5,130(a5) # 800088d0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	298a0a13          	addi	s4,s4,664 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	05048493          	addi	s1,s1,80 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	05098993          	addi	s3,s3,80 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	874080e7          	jalr	-1932(ra) # 8000211a <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	22650513          	addi	a0,a0,550 # 80010b08 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	348080e7          	jalr	840(ra) # 80000c32 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fce7a783          	lw	a5,-50(a5) # 800088c0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fd47b783          	ld	a5,-44(a5) # 800088d0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fc473703          	ld	a4,-60(a4) # 800088c8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	1f8a0a13          	addi	s4,s4,504 # 80010b08 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fb048493          	addi	s1,s1,-80 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fb090913          	addi	s2,s2,-80 # 800088d0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	786080e7          	jalr	1926(ra) # 800020b6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1c248493          	addi	s1,s1,450 # 80010b08 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f6f73b23          	sd	a5,-138(a4) # 800088d0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	37a080e7          	jalr	890(ra) # 80000ce6 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	13848493          	addi	s1,s1,312 # 80010b08 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	258080e7          	jalr	600(ra) # 80000c32 <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2fa080e7          	jalr	762(ra) # 80000ce6 <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	55e78793          	addi	a5,a5,1374 # 80021f70 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	304080e7          	jalr	772(ra) # 80000d2e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	10e90913          	addi	s2,s2,270 # 80010b40 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1f6080e7          	jalr	502(ra) # 80000c32 <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	296080e7          	jalr	662(ra) # 80000ce6 <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	07250513          	addi	a0,a0,114 # 80010b40 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	0cc080e7          	jalr	204(ra) # 80000ba2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	48e50513          	addi	a0,a0,1166 # 80021f70 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	03c48493          	addi	s1,s1,60 # 80010b40 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	124080e7          	jalr	292(ra) # 80000c32 <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	02450513          	addi	a0,a0,36 # 80010b40 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	1c0080e7          	jalr	448(ra) # 80000ce6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1fa080e7          	jalr	506(ra) # 80000d2e <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	ff850513          	addi	a0,a0,-8 # 80010b40 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	196080e7          	jalr	406(ra) # 80000ce6 <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <get_freeMemoryPageCount>:

// Lab 1
int get_freeMemoryPageCount()
{
    80000b5a:	1101                	addi	sp,sp,-32
    80000b5c:	ec06                	sd	ra,24(sp)
    80000b5e:	e822                	sd	s0,16(sp)
    80000b60:	e426                	sd	s1,8(sp)
    80000b62:	1000                	addi	s0,sp,32
  struct run *r;
  int free_pages = 0;
    
  // Acquire the lock to safely traverse the freelist
  acquire(&kmem.lock);
    80000b64:	00010497          	auipc	s1,0x10
    80000b68:	fdc48493          	addi	s1,s1,-36 # 80010b40 <kmem>
    80000b6c:	8526                	mv	a0,s1
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	0c4080e7          	jalr	196(ra) # 80000c32 <acquire>
    
  // Iterate through the freelist and count pages
  r = kmem.freelist;
    80000b76:	6c9c                	ld	a5,24(s1)
  while(r) {
    80000b78:	c39d                	beqz	a5,80000b9e <get_freeMemoryPageCount+0x44>
  int free_pages = 0;
    80000b7a:	4481                	li	s1,0
    free_pages++;
    80000b7c:	2485                	addiw	s1,s1,1
    r = r->next;
    80000b7e:	639c                	ld	a5,0(a5)
  while(r) {
    80000b80:	fff5                	bnez	a5,80000b7c <get_freeMemoryPageCount+0x22>
  }
    
  // Release the lock
  release(&kmem.lock);
    80000b82:	00010517          	auipc	a0,0x10
    80000b86:	fbe50513          	addi	a0,a0,-66 # 80010b40 <kmem>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	15c080e7          	jalr	348(ra) # 80000ce6 <release>
    
  return free_pages;
}
    80000b92:	8526                	mv	a0,s1
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret
  int free_pages = 0;
    80000b9e:	4481                	li	s1,0
    80000ba0:	b7cd                	j	80000b82 <get_freeMemoryPageCount+0x28>

0000000080000ba2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba2:	1141                	addi	sp,sp,-16
    80000ba4:	e422                	sd	s0,8(sp)
    80000ba6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ba8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000baa:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bae:	00053823          	sd	zero,16(a0)
}
    80000bb2:	6422                	ld	s0,8(sp)
    80000bb4:	0141                	addi	sp,sp,16
    80000bb6:	8082                	ret

0000000080000bb8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	411c                	lw	a5,0(a0)
    80000bba:	e399                	bnez	a5,80000bc0 <holding+0x8>
    80000bbc:	4501                	li	a0,0
  return r;
}
    80000bbe:	8082                	ret
{
    80000bc0:	1101                	addi	sp,sp,-32
    80000bc2:	ec06                	sd	ra,24(sp)
    80000bc4:	e822                	sd	s0,16(sp)
    80000bc6:	e426                	sd	s1,8(sp)
    80000bc8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bca:	6904                	ld	s1,16(a0)
    80000bcc:	00001097          	auipc	ra,0x1
    80000bd0:	e26080e7          	jalr	-474(ra) # 800019f2 <mycpu>
    80000bd4:	40a48533          	sub	a0,s1,a0
    80000bd8:	00153513          	seqz	a0,a0
}
    80000bdc:	60e2                	ld	ra,24(sp)
    80000bde:	6442                	ld	s0,16(sp)
    80000be0:	64a2                	ld	s1,8(sp)
    80000be2:	6105                	addi	sp,sp,32
    80000be4:	8082                	ret

0000000080000be6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf0:	100024f3          	csrr	s1,sstatus
    80000bf4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bf8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bfa:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bfe:	00001097          	auipc	ra,0x1
    80000c02:	df4080e7          	jalr	-524(ra) # 800019f2 <mycpu>
    80000c06:	5d3c                	lw	a5,120(a0)
    80000c08:	cf89                	beqz	a5,80000c22 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c0a:	00001097          	auipc	ra,0x1
    80000c0e:	de8080e7          	jalr	-536(ra) # 800019f2 <mycpu>
    80000c12:	5d3c                	lw	a5,120(a0)
    80000c14:	2785                	addiw	a5,a5,1
    80000c16:	dd3c                	sw	a5,120(a0)
}
    80000c18:	60e2                	ld	ra,24(sp)
    80000c1a:	6442                	ld	s0,16(sp)
    80000c1c:	64a2                	ld	s1,8(sp)
    80000c1e:	6105                	addi	sp,sp,32
    80000c20:	8082                	ret
    mycpu()->intena = old;
    80000c22:	00001097          	auipc	ra,0x1
    80000c26:	dd0080e7          	jalr	-560(ra) # 800019f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8085                	srli	s1,s1,0x1
    80000c2c:	8885                	andi	s1,s1,1
    80000c2e:	dd64                	sw	s1,124(a0)
    80000c30:	bfe9                	j	80000c0a <push_off+0x24>

0000000080000c32 <acquire>:
{
    80000c32:	1101                	addi	sp,sp,-32
    80000c34:	ec06                	sd	ra,24(sp)
    80000c36:	e822                	sd	s0,16(sp)
    80000c38:	e426                	sd	s1,8(sp)
    80000c3a:	1000                	addi	s0,sp,32
    80000c3c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	fa8080e7          	jalr	-88(ra) # 80000be6 <push_off>
  if(holding(lk))
    80000c46:	8526                	mv	a0,s1
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	f70080e7          	jalr	-144(ra) # 80000bb8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c50:	4705                	li	a4,1
  if(holding(lk))
    80000c52:	e115                	bnez	a0,80000c76 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c54:	87ba                	mv	a5,a4
    80000c56:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c5a:	2781                	sext.w	a5,a5
    80000c5c:	ffe5                	bnez	a5,80000c54 <acquire+0x22>
  __sync_synchronize();
    80000c5e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	d90080e7          	jalr	-624(ra) # 800019f2 <mycpu>
    80000c6a:	e888                	sd	a0,16(s1)
}
    80000c6c:	60e2                	ld	ra,24(sp)
    80000c6e:	6442                	ld	s0,16(sp)
    80000c70:	64a2                	ld	s1,8(sp)
    80000c72:	6105                	addi	sp,sp,32
    80000c74:	8082                	ret
    panic("acquire");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	3fa50513          	addi	a0,a0,1018 # 80008070 <digits+0x30>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8c6080e7          	jalr	-1850(ra) # 80000544 <panic>

0000000080000c86 <pop_off>:

void
pop_off(void)
{
    80000c86:	1141                	addi	sp,sp,-16
    80000c88:	e406                	sd	ra,8(sp)
    80000c8a:	e022                	sd	s0,0(sp)
    80000c8c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	d64080e7          	jalr	-668(ra) # 800019f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c96:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c9a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c9c:	e78d                	bnez	a5,80000cc6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c9e:	5d3c                	lw	a5,120(a0)
    80000ca0:	02f05b63          	blez	a5,80000cd6 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ca4:	37fd                	addiw	a5,a5,-1
    80000ca6:	0007871b          	sext.w	a4,a5
    80000caa:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cac:	eb09                	bnez	a4,80000cbe <pop_off+0x38>
    80000cae:	5d7c                	lw	a5,124(a0)
    80000cb0:	c799                	beqz	a5,80000cbe <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cba:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cbe:	60a2                	ld	ra,8(sp)
    80000cc0:	6402                	ld	s0,0(sp)
    80000cc2:	0141                	addi	sp,sp,16
    80000cc4:	8082                	ret
    panic("pop_off - interruptible");
    80000cc6:	00007517          	auipc	a0,0x7
    80000cca:	3b250513          	addi	a0,a0,946 # 80008078 <digits+0x38>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	876080e7          	jalr	-1930(ra) # 80000544 <panic>
    panic("pop_off");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3ba50513          	addi	a0,a0,954 # 80008090 <digits+0x50>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <release>:
{
    80000ce6:	1101                	addi	sp,sp,-32
    80000ce8:	ec06                	sd	ra,24(sp)
    80000cea:	e822                	sd	s0,16(sp)
    80000cec:	e426                	sd	s1,8(sp)
    80000cee:	1000                	addi	s0,sp,32
    80000cf0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	ec6080e7          	jalr	-314(ra) # 80000bb8 <holding>
    80000cfa:	c115                	beqz	a0,80000d1e <release+0x38>
  lk->cpu = 0;
    80000cfc:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d00:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d04:	0f50000f          	fence	iorw,ow
    80000d08:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	f7a080e7          	jalr	-134(ra) # 80000c86 <pop_off>
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    panic("release");
    80000d1e:	00007517          	auipc	a0,0x7
    80000d22:	37a50513          	addi	a0,a0,890 # 80008098 <digits+0x58>
    80000d26:	00000097          	auipc	ra,0x0
    80000d2a:	81e080e7          	jalr	-2018(ra) # 80000544 <panic>

0000000080000d2e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d34:	ce09                	beqz	a2,80000d4e <memset+0x20>
    80000d36:	87aa                	mv	a5,a0
    80000d38:	fff6071b          	addiw	a4,a2,-1
    80000d3c:	1702                	slli	a4,a4,0x20
    80000d3e:	9301                	srli	a4,a4,0x20
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d44:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d48:	0785                	addi	a5,a5,1
    80000d4a:	fee79de3          	bne	a5,a4,80000d44 <memset+0x16>
  }
  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret

0000000080000d54 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d54:	1141                	addi	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5a:	ca05                	beqz	a2,80000d8a <memcmp+0x36>
    80000d5c:	fff6069b          	addiw	a3,a2,-1
    80000d60:	1682                	slli	a3,a3,0x20
    80000d62:	9281                	srli	a3,a3,0x20
    80000d64:	0685                	addi	a3,a3,1
    80000d66:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d68:	00054783          	lbu	a5,0(a0)
    80000d6c:	0005c703          	lbu	a4,0(a1)
    80000d70:	00e79863          	bne	a5,a4,80000d80 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d74:	0505                	addi	a0,a0,1
    80000d76:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d78:	fed518e3          	bne	a0,a3,80000d68 <memcmp+0x14>
  }

  return 0;
    80000d7c:	4501                	li	a0,0
    80000d7e:	a019                	j	80000d84 <memcmp+0x30>
      return *s1 - *s2;
    80000d80:	40e7853b          	subw	a0,a5,a4
}
    80000d84:	6422                	ld	s0,8(sp)
    80000d86:	0141                	addi	sp,sp,16
    80000d88:	8082                	ret
  return 0;
    80000d8a:	4501                	li	a0,0
    80000d8c:	bfe5                	j	80000d84 <memcmp+0x30>

0000000080000d8e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d8e:	1141                	addi	sp,sp,-16
    80000d90:	e422                	sd	s0,8(sp)
    80000d92:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d94:	ca0d                	beqz	a2,80000dc6 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d96:	00a5f963          	bgeu	a1,a0,80000da8 <memmove+0x1a>
    80000d9a:	02061693          	slli	a3,a2,0x20
    80000d9e:	9281                	srli	a3,a3,0x20
    80000da0:	00d58733          	add	a4,a1,a3
    80000da4:	02e56463          	bltu	a0,a4,80000dcc <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da8:	fff6079b          	addiw	a5,a2,-1
    80000dac:	1782                	slli	a5,a5,0x20
    80000dae:	9381                	srli	a5,a5,0x20
    80000db0:	0785                	addi	a5,a5,1
    80000db2:	97ae                	add	a5,a5,a1
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x28>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
    d += n;
    80000dcc:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dce:	fff6079b          	addiw	a5,a2,-1
    80000dd2:	1782                	slli	a5,a5,0x20
    80000dd4:	9381                	srli	a5,a5,0x20
    80000dd6:	fff7c793          	not	a5,a5
    80000dda:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ddc:	177d                	addi	a4,a4,-1
    80000dde:	16fd                	addi	a3,a3,-1
    80000de0:	00074603          	lbu	a2,0(a4)
    80000de4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de8:	fef71ae3          	bne	a4,a5,80000ddc <memmove+0x4e>
    80000dec:	bfe9                	j	80000dc6 <memmove+0x38>

0000000080000dee <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dee:	1141                	addi	sp,sp,-16
    80000df0:	e406                	sd	ra,8(sp)
    80000df2:	e022                	sd	s0,0(sp)
    80000df4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df6:	00000097          	auipc	ra,0x0
    80000dfa:	f98080e7          	jalr	-104(ra) # 80000d8e <memmove>
}
    80000dfe:	60a2                	ld	ra,8(sp)
    80000e00:	6402                	ld	s0,0(sp)
    80000e02:	0141                	addi	sp,sp,16
    80000e04:	8082                	ret

0000000080000e06 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e06:	1141                	addi	sp,sp,-16
    80000e08:	e422                	sd	s0,8(sp)
    80000e0a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0c:	ce11                	beqz	a2,80000e28 <strncmp+0x22>
    80000e0e:	00054783          	lbu	a5,0(a0)
    80000e12:	cf89                	beqz	a5,80000e2c <strncmp+0x26>
    80000e14:	0005c703          	lbu	a4,0(a1)
    80000e18:	00f71a63          	bne	a4,a5,80000e2c <strncmp+0x26>
    n--, p++, q++;
    80000e1c:	367d                	addiw	a2,a2,-1
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e22:	f675                	bnez	a2,80000e0e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e24:	4501                	li	a0,0
    80000e26:	a809                	j	80000e38 <strncmp+0x32>
    80000e28:	4501                	li	a0,0
    80000e2a:	a039                	j	80000e38 <strncmp+0x32>
  if(n == 0)
    80000e2c:	ca09                	beqz	a2,80000e3e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e2e:	00054503          	lbu	a0,0(a0)
    80000e32:	0005c783          	lbu	a5,0(a1)
    80000e36:	9d1d                	subw	a0,a0,a5
}
    80000e38:	6422                	ld	s0,8(sp)
    80000e3a:	0141                	addi	sp,sp,16
    80000e3c:	8082                	ret
    return 0;
    80000e3e:	4501                	li	a0,0
    80000e40:	bfe5                	j	80000e38 <strncmp+0x32>

0000000080000e42 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e48:	872a                	mv	a4,a0
    80000e4a:	8832                	mv	a6,a2
    80000e4c:	367d                	addiw	a2,a2,-1
    80000e4e:	01005963          	blez	a6,80000e60 <strncpy+0x1e>
    80000e52:	0705                	addi	a4,a4,1
    80000e54:	0005c783          	lbu	a5,0(a1)
    80000e58:	fef70fa3          	sb	a5,-1(a4)
    80000e5c:	0585                	addi	a1,a1,1
    80000e5e:	f7f5                	bnez	a5,80000e4a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e60:	00c05d63          	blez	a2,80000e7a <strncpy+0x38>
    80000e64:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e66:	0685                	addi	a3,a3,1
    80000e68:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e6c:	fff6c793          	not	a5,a3
    80000e70:	9fb9                	addw	a5,a5,a4
    80000e72:	010787bb          	addw	a5,a5,a6
    80000e76:	fef048e3          	bgtz	a5,80000e66 <strncpy+0x24>
  return os;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret

0000000080000e80 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e86:	02c05363          	blez	a2,80000eac <safestrcpy+0x2c>
    80000e8a:	fff6069b          	addiw	a3,a2,-1
    80000e8e:	1682                	slli	a3,a3,0x20
    80000e90:	9281                	srli	a3,a3,0x20
    80000e92:	96ae                	add	a3,a3,a1
    80000e94:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e96:	00d58963          	beq	a1,a3,80000ea8 <safestrcpy+0x28>
    80000e9a:	0585                	addi	a1,a1,1
    80000e9c:	0785                	addi	a5,a5,1
    80000e9e:	fff5c703          	lbu	a4,-1(a1)
    80000ea2:	fee78fa3          	sb	a4,-1(a5)
    80000ea6:	fb65                	bnez	a4,80000e96 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ea8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret

0000000080000eb2 <strlen>:

int
strlen(const char *s)
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e422                	sd	s0,8(sp)
    80000eb6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eb8:	00054783          	lbu	a5,0(a0)
    80000ebc:	cf91                	beqz	a5,80000ed8 <strlen+0x26>
    80000ebe:	0505                	addi	a0,a0,1
    80000ec0:	87aa                	mv	a5,a0
    80000ec2:	4685                	li	a3,1
    80000ec4:	9e89                	subw	a3,a3,a0
    80000ec6:	00f6853b          	addw	a0,a3,a5
    80000eca:	0785                	addi	a5,a5,1
    80000ecc:	fff7c703          	lbu	a4,-1(a5)
    80000ed0:	fb7d                	bnez	a4,80000ec6 <strlen+0x14>
    ;
  return n;
}
    80000ed2:	6422                	ld	s0,8(sp)
    80000ed4:	0141                	addi	sp,sp,16
    80000ed6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ed8:	4501                	li	a0,0
    80000eda:	bfe5                	j	80000ed2 <strlen+0x20>

0000000080000edc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000edc:	1141                	addi	sp,sp,-16
    80000ede:	e406                	sd	ra,8(sp)
    80000ee0:	e022                	sd	s0,0(sp)
    80000ee2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	afe080e7          	jalr	-1282(ra) # 800019e2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eec:	00008717          	auipc	a4,0x8
    80000ef0:	9ec70713          	addi	a4,a4,-1556 # 800088d8 <started>
  if(cpuid() == 0){
    80000ef4:	c139                	beqz	a0,80000f3a <main+0x5e>
    while(started == 0)
    80000ef6:	431c                	lw	a5,0(a4)
    80000ef8:	2781                	sext.w	a5,a5
    80000efa:	dff5                	beqz	a5,80000ef6 <main+0x1a>
      ;
    __sync_synchronize();
    80000efc:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	ae2080e7          	jalr	-1310(ra) # 800019e2 <cpuid>
    80000f08:	85aa                	mv	a1,a0
    80000f0a:	00007517          	auipc	a0,0x7
    80000f0e:	1ae50513          	addi	a0,a0,430 # 800080b8 <digits+0x78>
    80000f12:	fffff097          	auipc	ra,0xfffff
    80000f16:	67c080e7          	jalr	1660(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	0d8080e7          	jalr	216(ra) # 80000ff2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f22:	00002097          	auipc	ra,0x2
    80000f26:	854080e7          	jalr	-1964(ra) # 80002776 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f2a:	00005097          	auipc	ra,0x5
    80000f2e:	e46080e7          	jalr	-442(ra) # 80005d70 <plicinithart>
  }

  scheduler();        
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	fd2080e7          	jalr	-46(ra) # 80001f04 <scheduler>
    consoleinit();
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	51c080e7          	jalr	1308(ra) # 80000456 <consoleinit>
    printfinit();
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	832080e7          	jalr	-1998(ra) # 80000774 <printfinit>
    printf("\n");
    80000f4a:	00007517          	auipc	a0,0x7
    80000f4e:	17e50513          	addi	a0,a0,382 # 800080c8 <digits+0x88>
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	63c080e7          	jalr	1596(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f5a:	00007517          	auipc	a0,0x7
    80000f5e:	14650513          	addi	a0,a0,326 # 800080a0 <digits+0x60>
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	62c080e7          	jalr	1580(ra) # 8000058e <printf>
    printf("\n");
    80000f6a:	00007517          	auipc	a0,0x7
    80000f6e:	15e50513          	addi	a0,a0,350 # 800080c8 <digits+0x88>
    80000f72:	fffff097          	auipc	ra,0xfffff
    80000f76:	61c080e7          	jalr	1564(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	b44080e7          	jalr	-1212(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	326080e7          	jalr	806(ra) # 800012a8 <kvminit>
    kvminithart();   // turn on paging
    80000f8a:	00000097          	auipc	ra,0x0
    80000f8e:	068080e7          	jalr	104(ra) # 80000ff2 <kvminithart>
    procinit();      // process table
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	99c080e7          	jalr	-1636(ra) # 8000192e <procinit>
    trapinit();      // trap vectors
    80000f9a:	00001097          	auipc	ra,0x1
    80000f9e:	7b4080e7          	jalr	1972(ra) # 8000274e <trapinit>
    trapinithart();  // install kernel trap vector
    80000fa2:	00001097          	auipc	ra,0x1
    80000fa6:	7d4080e7          	jalr	2004(ra) # 80002776 <trapinithart>
    plicinit();      // set up interrupt controller
    80000faa:	00005097          	auipc	ra,0x5
    80000fae:	db0080e7          	jalr	-592(ra) # 80005d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fb2:	00005097          	auipc	ra,0x5
    80000fb6:	dbe080e7          	jalr	-578(ra) # 80005d70 <plicinithart>
    binit();         // buffer cache
    80000fba:	00002097          	auipc	ra,0x2
    80000fbe:	f6e080e7          	jalr	-146(ra) # 80002f28 <binit>
    iinit();         // inode table
    80000fc2:	00002097          	auipc	ra,0x2
    80000fc6:	612080e7          	jalr	1554(ra) # 800035d4 <iinit>
    fileinit();      // file table
    80000fca:	00003097          	auipc	ra,0x3
    80000fce:	5b0080e7          	jalr	1456(ra) # 8000457a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fd2:	00005097          	auipc	ra,0x5
    80000fd6:	ea6080e7          	jalr	-346(ra) # 80005e78 <virtio_disk_init>
    userinit();      // first user process
    80000fda:	00001097          	auipc	ra,0x1
    80000fde:	d10080e7          	jalr	-752(ra) # 80001cea <userinit>
    __sync_synchronize();
    80000fe2:	0ff0000f          	fence
    started = 1;
    80000fe6:	4785                	li	a5,1
    80000fe8:	00008717          	auipc	a4,0x8
    80000fec:	8ef72823          	sw	a5,-1808(a4) # 800088d8 <started>
    80000ff0:	b789                	j	80000f32 <main+0x56>

0000000080000ff2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000ff2:	1141                	addi	sp,sp,-16
    80000ff4:	e422                	sd	s0,8(sp)
    80000ff6:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff8:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffc:	00008797          	auipc	a5,0x8
    80001000:	8e47b783          	ld	a5,-1820(a5) # 800088e0 <kernel_pagetable>
    80001004:	83b1                	srli	a5,a5,0xc
    80001006:	577d                	li	a4,-1
    80001008:	177e                	slli	a4,a4,0x3f
    8000100a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001010:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001014:	6422                	ld	s0,8(sp)
    80001016:	0141                	addi	sp,sp,16
    80001018:	8082                	ret

000000008000101a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000101a:	7139                	addi	sp,sp,-64
    8000101c:	fc06                	sd	ra,56(sp)
    8000101e:	f822                	sd	s0,48(sp)
    80001020:	f426                	sd	s1,40(sp)
    80001022:	f04a                	sd	s2,32(sp)
    80001024:	ec4e                	sd	s3,24(sp)
    80001026:	e852                	sd	s4,16(sp)
    80001028:	e456                	sd	s5,8(sp)
    8000102a:	e05a                	sd	s6,0(sp)
    8000102c:	0080                	addi	s0,sp,64
    8000102e:	84aa                	mv	s1,a0
    80001030:	89ae                	mv	s3,a1
    80001032:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001034:	57fd                	li	a5,-1
    80001036:	83e9                	srli	a5,a5,0x1a
    80001038:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000103a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000103c:	04b7f263          	bgeu	a5,a1,80001080 <walk+0x66>
    panic("walk");
    80001040:	00007517          	auipc	a0,0x7
    80001044:	09050513          	addi	a0,a0,144 # 800080d0 <digits+0x90>
    80001048:	fffff097          	auipc	ra,0xfffff
    8000104c:	4fc080e7          	jalr	1276(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001050:	060a8663          	beqz	s5,800010bc <walk+0xa2>
    80001054:	00000097          	auipc	ra,0x0
    80001058:	aa6080e7          	jalr	-1370(ra) # 80000afa <kalloc>
    8000105c:	84aa                	mv	s1,a0
    8000105e:	c529                	beqz	a0,800010a8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001060:	6605                	lui	a2,0x1
    80001062:	4581                	li	a1,0
    80001064:	00000097          	auipc	ra,0x0
    80001068:	cca080e7          	jalr	-822(ra) # 80000d2e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106c:	00c4d793          	srli	a5,s1,0xc
    80001070:	07aa                	slli	a5,a5,0xa
    80001072:	0017e793          	ori	a5,a5,1
    80001076:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000107a:	3a5d                	addiw	s4,s4,-9
    8000107c:	036a0063          	beq	s4,s6,8000109c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001080:	0149d933          	srl	s2,s3,s4
    80001084:	1ff97913          	andi	s2,s2,511
    80001088:	090e                	slli	s2,s2,0x3
    8000108a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000108c:	00093483          	ld	s1,0(s2)
    80001090:	0014f793          	andi	a5,s1,1
    80001094:	dfd5                	beqz	a5,80001050 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001096:	80a9                	srli	s1,s1,0xa
    80001098:	04b2                	slli	s1,s1,0xc
    8000109a:	b7c5                	j	8000107a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000109c:	00c9d513          	srli	a0,s3,0xc
    800010a0:	1ff57513          	andi	a0,a0,511
    800010a4:	050e                	slli	a0,a0,0x3
    800010a6:	9526                	add	a0,a0,s1
}
    800010a8:	70e2                	ld	ra,56(sp)
    800010aa:	7442                	ld	s0,48(sp)
    800010ac:	74a2                	ld	s1,40(sp)
    800010ae:	7902                	ld	s2,32(sp)
    800010b0:	69e2                	ld	s3,24(sp)
    800010b2:	6a42                	ld	s4,16(sp)
    800010b4:	6aa2                	ld	s5,8(sp)
    800010b6:	6b02                	ld	s6,0(sp)
    800010b8:	6121                	addi	sp,sp,64
    800010ba:	8082                	ret
        return 0;
    800010bc:	4501                	li	a0,0
    800010be:	b7ed                	j	800010a8 <walk+0x8e>

00000000800010c0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010c0:	57fd                	li	a5,-1
    800010c2:	83e9                	srli	a5,a5,0x1a
    800010c4:	00b7f463          	bgeu	a5,a1,800010cc <walkaddr+0xc>
    return 0;
    800010c8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ca:	8082                	ret
{
    800010cc:	1141                	addi	sp,sp,-16
    800010ce:	e406                	sd	ra,8(sp)
    800010d0:	e022                	sd	s0,0(sp)
    800010d2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d4:	4601                	li	a2,0
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	f44080e7          	jalr	-188(ra) # 8000101a <walk>
  if(pte == 0)
    800010de:	c105                	beqz	a0,800010fe <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010e0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010e2:	0117f693          	andi	a3,a5,17
    800010e6:	4745                	li	a4,17
    return 0;
    800010e8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ea:	00e68663          	beq	a3,a4,800010f6 <walkaddr+0x36>
}
    800010ee:	60a2                	ld	ra,8(sp)
    800010f0:	6402                	ld	s0,0(sp)
    800010f2:	0141                	addi	sp,sp,16
    800010f4:	8082                	ret
  pa = PTE2PA(*pte);
    800010f6:	00a7d513          	srli	a0,a5,0xa
    800010fa:	0532                	slli	a0,a0,0xc
  return pa;
    800010fc:	bfcd                	j	800010ee <walkaddr+0x2e>
    return 0;
    800010fe:	4501                	li	a0,0
    80001100:	b7fd                	j	800010ee <walkaddr+0x2e>

0000000080001102 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001102:	715d                	addi	sp,sp,-80
    80001104:	e486                	sd	ra,72(sp)
    80001106:	e0a2                	sd	s0,64(sp)
    80001108:	fc26                	sd	s1,56(sp)
    8000110a:	f84a                	sd	s2,48(sp)
    8000110c:	f44e                	sd	s3,40(sp)
    8000110e:	f052                	sd	s4,32(sp)
    80001110:	ec56                	sd	s5,24(sp)
    80001112:	e85a                	sd	s6,16(sp)
    80001114:	e45e                	sd	s7,8(sp)
    80001116:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001118:	c205                	beqz	a2,80001138 <mappages+0x36>
    8000111a:	8aaa                	mv	s5,a0
    8000111c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000111e:	77fd                	lui	a5,0xfffff
    80001120:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001124:	15fd                	addi	a1,a1,-1
    80001126:	00c589b3          	add	s3,a1,a2
    8000112a:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000112e:	8952                	mv	s2,s4
    80001130:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001134:	6b85                	lui	s7,0x1
    80001136:	a015                	j	8000115a <mappages+0x58>
    panic("mappages: size");
    80001138:	00007517          	auipc	a0,0x7
    8000113c:	fa050513          	addi	a0,a0,-96 # 800080d8 <digits+0x98>
    80001140:	fffff097          	auipc	ra,0xfffff
    80001144:	404080e7          	jalr	1028(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	fa050513          	addi	a0,a0,-96 # 800080e8 <digits+0xa8>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	3f4080e7          	jalr	1012(ra) # 80000544 <panic>
    a += PGSIZE;
    80001158:	995e                	add	s2,s2,s7
  for(;;){
    8000115a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115e:	4605                	li	a2,1
    80001160:	85ca                	mv	a1,s2
    80001162:	8556                	mv	a0,s5
    80001164:	00000097          	auipc	ra,0x0
    80001168:	eb6080e7          	jalr	-330(ra) # 8000101a <walk>
    8000116c:	cd19                	beqz	a0,8000118a <mappages+0x88>
    if(*pte & PTE_V)
    8000116e:	611c                	ld	a5,0(a0)
    80001170:	8b85                	andi	a5,a5,1
    80001172:	fbf9                	bnez	a5,80001148 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001174:	80b1                	srli	s1,s1,0xc
    80001176:	04aa                	slli	s1,s1,0xa
    80001178:	0164e4b3          	or	s1,s1,s6
    8000117c:	0014e493          	ori	s1,s1,1
    80001180:	e104                	sd	s1,0(a0)
    if(a == last)
    80001182:	fd391be3          	bne	s2,s3,80001158 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001186:	4501                	li	a0,0
    80001188:	a011                	j	8000118c <mappages+0x8a>
      return -1;
    8000118a:	557d                	li	a0,-1
}
    8000118c:	60a6                	ld	ra,72(sp)
    8000118e:	6406                	ld	s0,64(sp)
    80001190:	74e2                	ld	s1,56(sp)
    80001192:	7942                	ld	s2,48(sp)
    80001194:	79a2                	ld	s3,40(sp)
    80001196:	7a02                	ld	s4,32(sp)
    80001198:	6ae2                	ld	s5,24(sp)
    8000119a:	6b42                	ld	s6,16(sp)
    8000119c:	6ba2                	ld	s7,8(sp)
    8000119e:	6161                	addi	sp,sp,80
    800011a0:	8082                	ret

00000000800011a2 <kvmmap>:
{
    800011a2:	1141                	addi	sp,sp,-16
    800011a4:	e406                	sd	ra,8(sp)
    800011a6:	e022                	sd	s0,0(sp)
    800011a8:	0800                	addi	s0,sp,16
    800011aa:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011ac:	86b2                	mv	a3,a2
    800011ae:	863e                	mv	a2,a5
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	f52080e7          	jalr	-174(ra) # 80001102 <mappages>
    800011b8:	e509                	bnez	a0,800011c2 <kvmmap+0x20>
}
    800011ba:	60a2                	ld	ra,8(sp)
    800011bc:	6402                	ld	s0,0(sp)
    800011be:	0141                	addi	sp,sp,16
    800011c0:	8082                	ret
    panic("kvmmap");
    800011c2:	00007517          	auipc	a0,0x7
    800011c6:	f3650513          	addi	a0,a0,-202 # 800080f8 <digits+0xb8>
    800011ca:	fffff097          	auipc	ra,0xfffff
    800011ce:	37a080e7          	jalr	890(ra) # 80000544 <panic>

00000000800011d2 <kvmmake>:
{
    800011d2:	1101                	addi	sp,sp,-32
    800011d4:	ec06                	sd	ra,24(sp)
    800011d6:	e822                	sd	s0,16(sp)
    800011d8:	e426                	sd	s1,8(sp)
    800011da:	e04a                	sd	s2,0(sp)
    800011dc:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	91c080e7          	jalr	-1764(ra) # 80000afa <kalloc>
    800011e6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011e8:	6605                	lui	a2,0x1
    800011ea:	4581                	li	a1,0
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	b42080e7          	jalr	-1214(ra) # 80000d2e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011f4:	4719                	li	a4,6
    800011f6:	6685                	lui	a3,0x1
    800011f8:	10000637          	lui	a2,0x10000
    800011fc:	100005b7          	lui	a1,0x10000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	fa0080e7          	jalr	-96(ra) # 800011a2 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000120a:	4719                	li	a4,6
    8000120c:	6685                	lui	a3,0x1
    8000120e:	10001637          	lui	a2,0x10001
    80001212:	100015b7          	lui	a1,0x10001
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f8a080e7          	jalr	-118(ra) # 800011a2 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001220:	4719                	li	a4,6
    80001222:	004006b7          	lui	a3,0x400
    80001226:	0c000637          	lui	a2,0xc000
    8000122a:	0c0005b7          	lui	a1,0xc000
    8000122e:	8526                	mv	a0,s1
    80001230:	00000097          	auipc	ra,0x0
    80001234:	f72080e7          	jalr	-142(ra) # 800011a2 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001238:	00007917          	auipc	s2,0x7
    8000123c:	dc890913          	addi	s2,s2,-568 # 80008000 <etext>
    80001240:	4729                	li	a4,10
    80001242:	80007697          	auipc	a3,0x80007
    80001246:	dbe68693          	addi	a3,a3,-578 # 8000 <_entry-0x7fff8000>
    8000124a:	4605                	li	a2,1
    8000124c:	067e                	slli	a2,a2,0x1f
    8000124e:	85b2                	mv	a1,a2
    80001250:	8526                	mv	a0,s1
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f50080e7          	jalr	-176(ra) # 800011a2 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000125a:	4719                	li	a4,6
    8000125c:	46c5                	li	a3,17
    8000125e:	06ee                	slli	a3,a3,0x1b
    80001260:	412686b3          	sub	a3,a3,s2
    80001264:	864a                	mv	a2,s2
    80001266:	85ca                	mv	a1,s2
    80001268:	8526                	mv	a0,s1
    8000126a:	00000097          	auipc	ra,0x0
    8000126e:	f38080e7          	jalr	-200(ra) # 800011a2 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001272:	4729                	li	a4,10
    80001274:	6685                	lui	a3,0x1
    80001276:	00006617          	auipc	a2,0x6
    8000127a:	d8a60613          	addi	a2,a2,-630 # 80007000 <_trampoline>
    8000127e:	040005b7          	lui	a1,0x4000
    80001282:	15fd                	addi	a1,a1,-1
    80001284:	05b2                	slli	a1,a1,0xc
    80001286:	8526                	mv	a0,s1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	f1a080e7          	jalr	-230(ra) # 800011a2 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001290:	8526                	mv	a0,s1
    80001292:	00000097          	auipc	ra,0x0
    80001296:	606080e7          	jalr	1542(ra) # 80001898 <proc_mapstacks>
}
    8000129a:	8526                	mv	a0,s1
    8000129c:	60e2                	ld	ra,24(sp)
    8000129e:	6442                	ld	s0,16(sp)
    800012a0:	64a2                	ld	s1,8(sp)
    800012a2:	6902                	ld	s2,0(sp)
    800012a4:	6105                	addi	sp,sp,32
    800012a6:	8082                	ret

00000000800012a8 <kvminit>:
{
    800012a8:	1141                	addi	sp,sp,-16
    800012aa:	e406                	sd	ra,8(sp)
    800012ac:	e022                	sd	s0,0(sp)
    800012ae:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f22080e7          	jalr	-222(ra) # 800011d2 <kvmmake>
    800012b8:	00007797          	auipc	a5,0x7
    800012bc:	62a7b423          	sd	a0,1576(a5) # 800088e0 <kernel_pagetable>
}
    800012c0:	60a2                	ld	ra,8(sp)
    800012c2:	6402                	ld	s0,0(sp)
    800012c4:	0141                	addi	sp,sp,16
    800012c6:	8082                	ret

00000000800012c8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c8:	715d                	addi	sp,sp,-80
    800012ca:	e486                	sd	ra,72(sp)
    800012cc:	e0a2                	sd	s0,64(sp)
    800012ce:	fc26                	sd	s1,56(sp)
    800012d0:	f84a                	sd	s2,48(sp)
    800012d2:	f44e                	sd	s3,40(sp)
    800012d4:	f052                	sd	s4,32(sp)
    800012d6:	ec56                	sd	s5,24(sp)
    800012d8:	e85a                	sd	s6,16(sp)
    800012da:	e45e                	sd	s7,8(sp)
    800012dc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012de:	03459793          	slli	a5,a1,0x34
    800012e2:	e795                	bnez	a5,8000130e <uvmunmap+0x46>
    800012e4:	8a2a                	mv	s4,a0
    800012e6:	892e                	mv	s2,a1
    800012e8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ea:	0632                	slli	a2,a2,0xc
    800012ec:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f2:	6b05                	lui	s6,0x1
    800012f4:	0735e863          	bltu	a1,s3,80001364 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012f8:	60a6                	ld	ra,72(sp)
    800012fa:	6406                	ld	s0,64(sp)
    800012fc:	74e2                	ld	s1,56(sp)
    800012fe:	7942                	ld	s2,48(sp)
    80001300:	79a2                	ld	s3,40(sp)
    80001302:	7a02                	ld	s4,32(sp)
    80001304:	6ae2                	ld	s5,24(sp)
    80001306:	6b42                	ld	s6,16(sp)
    80001308:	6ba2                	ld	s7,8(sp)
    8000130a:	6161                	addi	sp,sp,80
    8000130c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	df250513          	addi	a0,a0,-526 # 80008100 <digits+0xc0>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	22e080e7          	jalr	558(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dfa50513          	addi	a0,a0,-518 # 80008118 <digits+0xd8>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	21e080e7          	jalr	542(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	dfa50513          	addi	a0,a0,-518 # 80008128 <digits+0xe8>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	20e080e7          	jalr	526(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    8000133e:	00007517          	auipc	a0,0x7
    80001342:	e0250513          	addi	a0,a0,-510 # 80008140 <digits+0x100>
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	1fe080e7          	jalr	510(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    8000134e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001350:	0532                	slli	a0,a0,0xc
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	6ac080e7          	jalr	1708(ra) # 800009fe <kfree>
    *pte = 0;
    8000135a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135e:	995a                	add	s2,s2,s6
    80001360:	f9397ce3          	bgeu	s2,s3,800012f8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001364:	4601                	li	a2,0
    80001366:	85ca                	mv	a1,s2
    80001368:	8552                	mv	a0,s4
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	cb0080e7          	jalr	-848(ra) # 8000101a <walk>
    80001372:	84aa                	mv	s1,a0
    80001374:	d54d                	beqz	a0,8000131e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001376:	6108                	ld	a0,0(a0)
    80001378:	00157793          	andi	a5,a0,1
    8000137c:	dbcd                	beqz	a5,8000132e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000137e:	3ff57793          	andi	a5,a0,1023
    80001382:	fb778ee3          	beq	a5,s7,8000133e <uvmunmap+0x76>
    if(do_free){
    80001386:	fc0a8ae3          	beqz	s5,8000135a <uvmunmap+0x92>
    8000138a:	b7d1                	j	8000134e <uvmunmap+0x86>

000000008000138c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000138c:	1101                	addi	sp,sp,-32
    8000138e:	ec06                	sd	ra,24(sp)
    80001390:	e822                	sd	s0,16(sp)
    80001392:	e426                	sd	s1,8(sp)
    80001394:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	764080e7          	jalr	1892(ra) # 80000afa <kalloc>
    8000139e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a0:	c519                	beqz	a0,800013ae <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a2:	6605                	lui	a2,0x1
    800013a4:	4581                	li	a1,0
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	988080e7          	jalr	-1656(ra) # 80000d2e <memset>
  return pagetable;
}
    800013ae:	8526                	mv	a0,s1
    800013b0:	60e2                	ld	ra,24(sp)
    800013b2:	6442                	ld	s0,16(sp)
    800013b4:	64a2                	ld	s1,8(sp)
    800013b6:	6105                	addi	sp,sp,32
    800013b8:	8082                	ret

00000000800013ba <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ba:	7179                	addi	sp,sp,-48
    800013bc:	f406                	sd	ra,40(sp)
    800013be:	f022                	sd	s0,32(sp)
    800013c0:	ec26                	sd	s1,24(sp)
    800013c2:	e84a                	sd	s2,16(sp)
    800013c4:	e44e                	sd	s3,8(sp)
    800013c6:	e052                	sd	s4,0(sp)
    800013c8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ca:	6785                	lui	a5,0x1
    800013cc:	04f67863          	bgeu	a2,a5,8000141c <uvmfirst+0x62>
    800013d0:	8a2a                	mv	s4,a0
    800013d2:	89ae                	mv	s3,a1
    800013d4:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	724080e7          	jalr	1828(ra) # 80000afa <kalloc>
    800013de:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e0:	6605                	lui	a2,0x1
    800013e2:	4581                	li	a1,0
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	94a080e7          	jalr	-1718(ra) # 80000d2e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ec:	4779                	li	a4,30
    800013ee:	86ca                	mv	a3,s2
    800013f0:	6605                	lui	a2,0x1
    800013f2:	4581                	li	a1,0
    800013f4:	8552                	mv	a0,s4
    800013f6:	00000097          	auipc	ra,0x0
    800013fa:	d0c080e7          	jalr	-756(ra) # 80001102 <mappages>
  memmove(mem, src, sz);
    800013fe:	8626                	mv	a2,s1
    80001400:	85ce                	mv	a1,s3
    80001402:	854a                	mv	a0,s2
    80001404:	00000097          	auipc	ra,0x0
    80001408:	98a080e7          	jalr	-1654(ra) # 80000d8e <memmove>
}
    8000140c:	70a2                	ld	ra,40(sp)
    8000140e:	7402                	ld	s0,32(sp)
    80001410:	64e2                	ld	s1,24(sp)
    80001412:	6942                	ld	s2,16(sp)
    80001414:	69a2                	ld	s3,8(sp)
    80001416:	6a02                	ld	s4,0(sp)
    80001418:	6145                	addi	sp,sp,48
    8000141a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	d3c50513          	addi	a0,a0,-708 # 80008158 <digits+0x118>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	120080e7          	jalr	288(ra) # 80000544 <panic>

000000008000142c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000142c:	1101                	addi	sp,sp,-32
    8000142e:	ec06                	sd	ra,24(sp)
    80001430:	e822                	sd	s0,16(sp)
    80001432:	e426                	sd	s1,8(sp)
    80001434:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001436:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001438:	00b67d63          	bgeu	a2,a1,80001452 <uvmdealloc+0x26>
    8000143c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000143e:	6785                	lui	a5,0x1
    80001440:	17fd                	addi	a5,a5,-1
    80001442:	00f60733          	add	a4,a2,a5
    80001446:	767d                	lui	a2,0xfffff
    80001448:	8f71                	and	a4,a4,a2
    8000144a:	97ae                	add	a5,a5,a1
    8000144c:	8ff1                	and	a5,a5,a2
    8000144e:	00f76863          	bltu	a4,a5,8000145e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001452:	8526                	mv	a0,s1
    80001454:	60e2                	ld	ra,24(sp)
    80001456:	6442                	ld	s0,16(sp)
    80001458:	64a2                	ld	s1,8(sp)
    8000145a:	6105                	addi	sp,sp,32
    8000145c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000145e:	8f99                	sub	a5,a5,a4
    80001460:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001462:	4685                	li	a3,1
    80001464:	0007861b          	sext.w	a2,a5
    80001468:	85ba                	mv	a1,a4
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	e5e080e7          	jalr	-418(ra) # 800012c8 <uvmunmap>
    80001472:	b7c5                	j	80001452 <uvmdealloc+0x26>

0000000080001474 <uvmalloc>:
  if(newsz < oldsz)
    80001474:	0ab66563          	bltu	a2,a1,8000151e <uvmalloc+0xaa>
{
    80001478:	7139                	addi	sp,sp,-64
    8000147a:	fc06                	sd	ra,56(sp)
    8000147c:	f822                	sd	s0,48(sp)
    8000147e:	f426                	sd	s1,40(sp)
    80001480:	f04a                	sd	s2,32(sp)
    80001482:	ec4e                	sd	s3,24(sp)
    80001484:	e852                	sd	s4,16(sp)
    80001486:	e456                	sd	s5,8(sp)
    80001488:	e05a                	sd	s6,0(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6985                	lui	s3,0x1
    80001492:	19fd                	addi	s3,s3,-1
    80001494:	95ce                	add	a1,a1,s3
    80001496:	79fd                	lui	s3,0xfffff
    80001498:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9f363          	bgeu	s3,a2,80001522 <uvmalloc+0xae>
    800014a0:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a2:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014a6:	fffff097          	auipc	ra,0xfffff
    800014aa:	654080e7          	jalr	1620(ra) # 80000afa <kalloc>
    800014ae:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b0:	c51d                	beqz	a0,800014de <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	878080e7          	jalr	-1928(ra) # 80000d2e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014be:	875a                	mv	a4,s6
    800014c0:	86a6                	mv	a3,s1
    800014c2:	6605                	lui	a2,0x1
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	c3a080e7          	jalr	-966(ra) # 80001102 <mappages>
    800014d0:	e90d                	bnez	a0,80001502 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d2:	6785                	lui	a5,0x1
    800014d4:	993e                	add	s2,s2,a5
    800014d6:	fd4968e3          	bltu	s2,s4,800014a6 <uvmalloc+0x32>
  return newsz;
    800014da:	8552                	mv	a0,s4
    800014dc:	a809                	j	800014ee <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014de:	864e                	mv	a2,s3
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8556                	mv	a0,s5
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f48080e7          	jalr	-184(ra) # 8000142c <uvmdealloc>
      return 0;
    800014ec:	4501                	li	a0,0
}
    800014ee:	70e2                	ld	ra,56(sp)
    800014f0:	7442                	ld	s0,48(sp)
    800014f2:	74a2                	ld	s1,40(sp)
    800014f4:	7902                	ld	s2,32(sp)
    800014f6:	69e2                	ld	s3,24(sp)
    800014f8:	6a42                	ld	s4,16(sp)
    800014fa:	6aa2                	ld	s5,8(sp)
    800014fc:	6b02                	ld	s6,0(sp)
    800014fe:	6121                	addi	sp,sp,64
    80001500:	8082                	ret
      kfree(mem);
    80001502:	8526                	mv	a0,s1
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4fa080e7          	jalr	1274(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000150c:	864e                	mv	a2,s3
    8000150e:	85ca                	mv	a1,s2
    80001510:	8556                	mv	a0,s5
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f1a080e7          	jalr	-230(ra) # 8000142c <uvmdealloc>
      return 0;
    8000151a:	4501                	li	a0,0
    8000151c:	bfc9                	j	800014ee <uvmalloc+0x7a>
    return oldsz;
    8000151e:	852e                	mv	a0,a1
}
    80001520:	8082                	ret
  return newsz;
    80001522:	8532                	mv	a0,a2
    80001524:	b7e9                	j	800014ee <uvmalloc+0x7a>

0000000080001526 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001526:	7179                	addi	sp,sp,-48
    80001528:	f406                	sd	ra,40(sp)
    8000152a:	f022                	sd	s0,32(sp)
    8000152c:	ec26                	sd	s1,24(sp)
    8000152e:	e84a                	sd	s2,16(sp)
    80001530:	e44e                	sd	s3,8(sp)
    80001532:	e052                	sd	s4,0(sp)
    80001534:	1800                	addi	s0,sp,48
    80001536:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001538:	84aa                	mv	s1,a0
    8000153a:	6905                	lui	s2,0x1
    8000153c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000153e:	4985                	li	s3,1
    80001540:	a821                	j	80001558 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001542:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001544:	0532                	slli	a0,a0,0xc
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	fe0080e7          	jalr	-32(ra) # 80001526 <freewalk>
      pagetable[i] = 0;
    8000154e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001552:	04a1                	addi	s1,s1,8
    80001554:	03248163          	beq	s1,s2,80001576 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001558:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000155a:	00f57793          	andi	a5,a0,15
    8000155e:	ff3782e3          	beq	a5,s3,80001542 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001562:	8905                	andi	a0,a0,1
    80001564:	d57d                	beqz	a0,80001552 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	c1250513          	addi	a0,a0,-1006 # 80008178 <digits+0x138>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fd6080e7          	jalr	-42(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    80001576:	8552                	mv	a0,s4
    80001578:	fffff097          	auipc	ra,0xfffff
    8000157c:	486080e7          	jalr	1158(ra) # 800009fe <kfree>
}
    80001580:	70a2                	ld	ra,40(sp)
    80001582:	7402                	ld	s0,32(sp)
    80001584:	64e2                	ld	s1,24(sp)
    80001586:	6942                	ld	s2,16(sp)
    80001588:	69a2                	ld	s3,8(sp)
    8000158a:	6a02                	ld	s4,0(sp)
    8000158c:	6145                	addi	sp,sp,48
    8000158e:	8082                	ret

0000000080001590 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001590:	1101                	addi	sp,sp,-32
    80001592:	ec06                	sd	ra,24(sp)
    80001594:	e822                	sd	s0,16(sp)
    80001596:	e426                	sd	s1,8(sp)
    80001598:	1000                	addi	s0,sp,32
    8000159a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000159c:	e999                	bnez	a1,800015b2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000159e:	8526                	mv	a0,s1
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	f86080e7          	jalr	-122(ra) # 80001526 <freewalk>
}
    800015a8:	60e2                	ld	ra,24(sp)
    800015aa:	6442                	ld	s0,16(sp)
    800015ac:	64a2                	ld	s1,8(sp)
    800015ae:	6105                	addi	sp,sp,32
    800015b0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	167d                	addi	a2,a2,-1
    800015b6:	962e                	add	a2,a2,a1
    800015b8:	4685                	li	a3,1
    800015ba:	8231                	srli	a2,a2,0xc
    800015bc:	4581                	li	a1,0
    800015be:	00000097          	auipc	ra,0x0
    800015c2:	d0a080e7          	jalr	-758(ra) # 800012c8 <uvmunmap>
    800015c6:	bfe1                	j	8000159e <uvmfree+0xe>

00000000800015c8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015c8:	c679                	beqz	a2,80001696 <uvmcopy+0xce>
{
    800015ca:	715d                	addi	sp,sp,-80
    800015cc:	e486                	sd	ra,72(sp)
    800015ce:	e0a2                	sd	s0,64(sp)
    800015d0:	fc26                	sd	s1,56(sp)
    800015d2:	f84a                	sd	s2,48(sp)
    800015d4:	f44e                	sd	s3,40(sp)
    800015d6:	f052                	sd	s4,32(sp)
    800015d8:	ec56                	sd	s5,24(sp)
    800015da:	e85a                	sd	s6,16(sp)
    800015dc:	e45e                	sd	s7,8(sp)
    800015de:	0880                	addi	s0,sp,80
    800015e0:	8b2a                	mv	s6,a0
    800015e2:	8aae                	mv	s5,a1
    800015e4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015e8:	4601                	li	a2,0
    800015ea:	85ce                	mv	a1,s3
    800015ec:	855a                	mv	a0,s6
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	a2c080e7          	jalr	-1492(ra) # 8000101a <walk>
    800015f6:	c531                	beqz	a0,80001642 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015f8:	6118                	ld	a4,0(a0)
    800015fa:	00177793          	andi	a5,a4,1
    800015fe:	cbb1                	beqz	a5,80001652 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001600:	00a75593          	srli	a1,a4,0xa
    80001604:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001608:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	4ee080e7          	jalr	1262(ra) # 80000afa <kalloc>
    80001614:	892a                	mv	s2,a0
    80001616:	c939                	beqz	a0,8000166c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001618:	6605                	lui	a2,0x1
    8000161a:	85de                	mv	a1,s7
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	772080e7          	jalr	1906(ra) # 80000d8e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001624:	8726                	mv	a4,s1
    80001626:	86ca                	mv	a3,s2
    80001628:	6605                	lui	a2,0x1
    8000162a:	85ce                	mv	a1,s3
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	ad4080e7          	jalr	-1324(ra) # 80001102 <mappages>
    80001636:	e515                	bnez	a0,80001662 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001638:	6785                	lui	a5,0x1
    8000163a:	99be                	add	s3,s3,a5
    8000163c:	fb49e6e3          	bltu	s3,s4,800015e8 <uvmcopy+0x20>
    80001640:	a081                	j	80001680 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001642:	00007517          	auipc	a0,0x7
    80001646:	b4650513          	addi	a0,a0,-1210 # 80008188 <digits+0x148>
    8000164a:	fffff097          	auipc	ra,0xfffff
    8000164e:	efa080e7          	jalr	-262(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    80001652:	00007517          	auipc	a0,0x7
    80001656:	b5650513          	addi	a0,a0,-1194 # 800081a8 <digits+0x168>
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	eea080e7          	jalr	-278(ra) # 80000544 <panic>
      kfree(mem);
    80001662:	854a                	mv	a0,s2
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	39a080e7          	jalr	922(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000166c:	4685                	li	a3,1
    8000166e:	00c9d613          	srli	a2,s3,0xc
    80001672:	4581                	li	a1,0
    80001674:	8556                	mv	a0,s5
    80001676:	00000097          	auipc	ra,0x0
    8000167a:	c52080e7          	jalr	-942(ra) # 800012c8 <uvmunmap>
  return -1;
    8000167e:	557d                	li	a0,-1
}
    80001680:	60a6                	ld	ra,72(sp)
    80001682:	6406                	ld	s0,64(sp)
    80001684:	74e2                	ld	s1,56(sp)
    80001686:	7942                	ld	s2,48(sp)
    80001688:	79a2                	ld	s3,40(sp)
    8000168a:	7a02                	ld	s4,32(sp)
    8000168c:	6ae2                	ld	s5,24(sp)
    8000168e:	6b42                	ld	s6,16(sp)
    80001690:	6ba2                	ld	s7,8(sp)
    80001692:	6161                	addi	sp,sp,80
    80001694:	8082                	ret
  return 0;
    80001696:	4501                	li	a0,0
}
    80001698:	8082                	ret

000000008000169a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000169a:	1141                	addi	sp,sp,-16
    8000169c:	e406                	sd	ra,8(sp)
    8000169e:	e022                	sd	s0,0(sp)
    800016a0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a2:	4601                	li	a2,0
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	976080e7          	jalr	-1674(ra) # 8000101a <walk>
  if(pte == 0)
    800016ac:	c901                	beqz	a0,800016bc <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016ae:	611c                	ld	a5,0(a0)
    800016b0:	9bbd                	andi	a5,a5,-17
    800016b2:	e11c                	sd	a5,0(a0)
}
    800016b4:	60a2                	ld	ra,8(sp)
    800016b6:	6402                	ld	s0,0(sp)
    800016b8:	0141                	addi	sp,sp,16
    800016ba:	8082                	ret
    panic("uvmclear");
    800016bc:	00007517          	auipc	a0,0x7
    800016c0:	b0c50513          	addi	a0,a0,-1268 # 800081c8 <digits+0x188>
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	e80080e7          	jalr	-384(ra) # 80000544 <panic>

00000000800016cc <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016cc:	c6bd                	beqz	a3,8000173a <copyout+0x6e>
{
    800016ce:	715d                	addi	sp,sp,-80
    800016d0:	e486                	sd	ra,72(sp)
    800016d2:	e0a2                	sd	s0,64(sp)
    800016d4:	fc26                	sd	s1,56(sp)
    800016d6:	f84a                	sd	s2,48(sp)
    800016d8:	f44e                	sd	s3,40(sp)
    800016da:	f052                	sd	s4,32(sp)
    800016dc:	ec56                	sd	s5,24(sp)
    800016de:	e85a                	sd	s6,16(sp)
    800016e0:	e45e                	sd	s7,8(sp)
    800016e2:	e062                	sd	s8,0(sp)
    800016e4:	0880                	addi	s0,sp,80
    800016e6:	8b2a                	mv	s6,a0
    800016e8:	8c2e                	mv	s8,a1
    800016ea:	8a32                	mv	s4,a2
    800016ec:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ee:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016f0:	6a85                	lui	s5,0x1
    800016f2:	a015                	j	80001716 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016f4:	9562                	add	a0,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	85d2                	mv	a1,s4
    800016fc:	41250533          	sub	a0,a0,s2
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	68e080e7          	jalr	1678(ra) # 80000d8e <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    src += n;
    8000170c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	9a2080e7          	jalr	-1630(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f3e3          	bgeu	s3,s1,800016f4 <copyout+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	b7c1                	j	800016f4 <copyout+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyout+0x74>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001758:	c6bd                	beqz	a3,800017c6 <copyin+0x6e>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	e062                	sd	s8,0(sp)
    80001770:	0880                	addi	s0,sp,80
    80001772:	8b2a                	mv	s6,a0
    80001774:	8a2e                	mv	s4,a1
    80001776:	8c32                	mv	s8,a2
    80001778:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000177a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177c:	6a85                	lui	s5,0x1
    8000177e:	a015                	j	800017a2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001780:	9562                	add	a0,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	412505b3          	sub	a1,a0,s2
    8000178a:	8552                	mv	a0,s4
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	602080e7          	jalr	1538(ra) # 80000d8e <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001798:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	916080e7          	jalr	-1770(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f3e3          	bgeu	s3,s1,80001780 <copyin+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	b7c1                	j	80001780 <copyin+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyin+0x74>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017e4:	c6c5                	beqz	a3,8000188c <copyinstr+0xa8>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	0880                	addi	s0,sp,80
    800017fc:	8a2a                	mv	s4,a0
    800017fe:	8b2e                	mv	s6,a1
    80001800:	8bb2                	mv	s7,a2
    80001802:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001804:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001806:	6985                	lui	s3,0x1
    80001808:	a035                	j	80001834 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000180a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000180e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001810:	0017b793          	seqz	a5,a5
    80001814:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001818:	60a6                	ld	ra,72(sp)
    8000181a:	6406                	ld	s0,64(sp)
    8000181c:	74e2                	ld	s1,56(sp)
    8000181e:	7942                	ld	s2,48(sp)
    80001820:	79a2                	ld	s3,40(sp)
    80001822:	7a02                	ld	s4,32(sp)
    80001824:	6ae2                	ld	s5,24(sp)
    80001826:	6b42                	ld	s6,16(sp)
    80001828:	6ba2                	ld	s7,8(sp)
    8000182a:	6161                	addi	sp,sp,80
    8000182c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000182e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001832:	c8a9                	beqz	s1,80001884 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001834:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001838:	85ca                	mv	a1,s2
    8000183a:	8552                	mv	a0,s4
    8000183c:	00000097          	auipc	ra,0x0
    80001840:	884080e7          	jalr	-1916(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    80001844:	c131                	beqz	a0,80001888 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001846:	41790833          	sub	a6,s2,s7
    8000184a:	984e                	add	a6,a6,s3
    if(n > max)
    8000184c:	0104f363          	bgeu	s1,a6,80001852 <copyinstr+0x6e>
    80001850:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001852:	955e                	add	a0,a0,s7
    80001854:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001858:	fc080be3          	beqz	a6,8000182e <copyinstr+0x4a>
    8000185c:	985a                	add	a6,a6,s6
    8000185e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001860:	41650633          	sub	a2,a0,s6
    80001864:	14fd                	addi	s1,s1,-1
    80001866:	9b26                	add	s6,s6,s1
    80001868:	00f60733          	add	a4,a2,a5
    8000186c:	00074703          	lbu	a4,0(a4)
    80001870:	df49                	beqz	a4,8000180a <copyinstr+0x26>
        *dst = *p;
    80001872:	00e78023          	sb	a4,0(a5)
      --max;
    80001876:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000187a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000187c:	ff0796e3          	bne	a5,a6,80001868 <copyinstr+0x84>
      dst++;
    80001880:	8b42                	mv	s6,a6
    80001882:	b775                	j	8000182e <copyinstr+0x4a>
    80001884:	4781                	li	a5,0
    80001886:	b769                	j	80001810 <copyinstr+0x2c>
      return -1;
    80001888:	557d                	li	a0,-1
    8000188a:	b779                	j	80001818 <copyinstr+0x34>
  int got_null = 0;
    8000188c:	4781                	li	a5,0
  if(got_null){
    8000188e:	0017b793          	seqz	a5,a5
    80001892:	40f00533          	neg	a0,a5
}
    80001896:	8082                	ret

0000000080001898 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001898:	7139                	addi	sp,sp,-64
    8000189a:	fc06                	sd	ra,56(sp)
    8000189c:	f822                	sd	s0,48(sp)
    8000189e:	f426                	sd	s1,40(sp)
    800018a0:	f04a                	sd	s2,32(sp)
    800018a2:	ec4e                	sd	s3,24(sp)
    800018a4:	e852                	sd	s4,16(sp)
    800018a6:	e456                	sd	s5,8(sp)
    800018a8:	e05a                	sd	s6,0(sp)
    800018aa:	0080                	addi	s0,sp,64
    800018ac:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ae:	0000f497          	auipc	s1,0xf
    800018b2:	6e248493          	addi	s1,s1,1762 # 80010f90 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018b6:	8b26                	mv	s6,s1
    800018b8:	00006a97          	auipc	s5,0x6
    800018bc:	748a8a93          	addi	s5,s5,1864 # 80008000 <etext>
    800018c0:	04000937          	lui	s2,0x4000
    800018c4:	197d                	addi	s2,s2,-1
    800018c6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c8:	00015a17          	auipc	s4,0x15
    800018cc:	2c8a0a13          	addi	s4,s4,712 # 80016b90 <tickslock>
    char *pa = kalloc();
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	22a080e7          	jalr	554(ra) # 80000afa <kalloc>
    800018d8:	862a                	mv	a2,a0
    if(pa == 0)
    800018da:	c131                	beqz	a0,8000191e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018dc:	416485b3          	sub	a1,s1,s6
    800018e0:	8591                	srai	a1,a1,0x4
    800018e2:	000ab783          	ld	a5,0(s5)
    800018e6:	02f585b3          	mul	a1,a1,a5
    800018ea:	2585                	addiw	a1,a1,1
    800018ec:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018f0:	4719                	li	a4,6
    800018f2:	6685                	lui	a3,0x1
    800018f4:	40b905b3          	sub	a1,s2,a1
    800018f8:	854e                	mv	a0,s3
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	8a8080e7          	jalr	-1880(ra) # 800011a2 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001902:	17048493          	addi	s1,s1,368
    80001906:	fd4495e3          	bne	s1,s4,800018d0 <proc_mapstacks+0x38>
  }
}
    8000190a:	70e2                	ld	ra,56(sp)
    8000190c:	7442                	ld	s0,48(sp)
    8000190e:	74a2                	ld	s1,40(sp)
    80001910:	7902                	ld	s2,32(sp)
    80001912:	69e2                	ld	s3,24(sp)
    80001914:	6a42                	ld	s4,16(sp)
    80001916:	6aa2                	ld	s5,8(sp)
    80001918:	6b02                	ld	s6,0(sp)
    8000191a:	6121                	addi	sp,sp,64
    8000191c:	8082                	ret
      panic("kalloc");
    8000191e:	00007517          	auipc	a0,0x7
    80001922:	8ba50513          	addi	a0,a0,-1862 # 800081d8 <digits+0x198>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	c1e080e7          	jalr	-994(ra) # 80000544 <panic>

000000008000192e <procinit>:

// initialize the proc table.
void
procinit(void)
{
    8000192e:	7139                	addi	sp,sp,-64
    80001930:	fc06                	sd	ra,56(sp)
    80001932:	f822                	sd	s0,48(sp)
    80001934:	f426                	sd	s1,40(sp)
    80001936:	f04a                	sd	s2,32(sp)
    80001938:	ec4e                	sd	s3,24(sp)
    8000193a:	e852                	sd	s4,16(sp)
    8000193c:	e456                	sd	s5,8(sp)
    8000193e:	e05a                	sd	s6,0(sp)
    80001940:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	89e58593          	addi	a1,a1,-1890 # 800081e0 <digits+0x1a0>
    8000194a:	0000f517          	auipc	a0,0xf
    8000194e:	21650513          	addi	a0,a0,534 # 80010b60 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	250080e7          	jalr	592(ra) # 80000ba2 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000195a:	00007597          	auipc	a1,0x7
    8000195e:	88e58593          	addi	a1,a1,-1906 # 800081e8 <digits+0x1a8>
    80001962:	0000f517          	auipc	a0,0xf
    80001966:	21650513          	addi	a0,a0,534 # 80010b78 <wait_lock>
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	238080e7          	jalr	568(ra) # 80000ba2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001972:	0000f497          	auipc	s1,0xf
    80001976:	61e48493          	addi	s1,s1,1566 # 80010f90 <proc>
      initlock(&p->lock, "proc");
    8000197a:	00007b17          	auipc	s6,0x7
    8000197e:	87eb0b13          	addi	s6,s6,-1922 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001982:	8aa6                	mv	s5,s1
    80001984:	00006a17          	auipc	s4,0x6
    80001988:	67ca0a13          	addi	s4,s4,1660 # 80008000 <etext>
    8000198c:	04000937          	lui	s2,0x4000
    80001990:	197d                	addi	s2,s2,-1
    80001992:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00015997          	auipc	s3,0x15
    80001998:	1fc98993          	addi	s3,s3,508 # 80016b90 <tickslock>
      initlock(&p->lock, "proc");
    8000199c:	85da                	mv	a1,s6
    8000199e:	8526                	mv	a0,s1
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	202080e7          	jalr	514(ra) # 80000ba2 <initlock>
      p->state = UNUSED;
    800019a8:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019ac:	415487b3          	sub	a5,s1,s5
    800019b0:	8791                	srai	a5,a5,0x4
    800019b2:	000a3703          	ld	a4,0(s4)
    800019b6:	02e787b3          	mul	a5,a5,a4
    800019ba:	2785                	addiw	a5,a5,1
    800019bc:	00d7979b          	slliw	a5,a5,0xd
    800019c0:	40f907b3          	sub	a5,s2,a5
    800019c4:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	17048493          	addi	s1,s1,368
    800019ca:	fd3499e3          	bne	s1,s3,8000199c <procinit+0x6e>
  }
}
    800019ce:	70e2                	ld	ra,56(sp)
    800019d0:	7442                	ld	s0,48(sp)
    800019d2:	74a2                	ld	s1,40(sp)
    800019d4:	7902                	ld	s2,32(sp)
    800019d6:	69e2                	ld	s3,24(sp)
    800019d8:	6a42                	ld	s4,16(sp)
    800019da:	6aa2                	ld	s5,8(sp)
    800019dc:	6b02                	ld	s6,0(sp)
    800019de:	6121                	addi	sp,sp,64
    800019e0:	8082                	ret

00000000800019e2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019e2:	1141                	addi	sp,sp,-16
    800019e4:	e422                	sd	s0,8(sp)
    800019e6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ea:	2501                	sext.w	a0,a0
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e422                	sd	s0,8(sp)
    800019f6:	0800                	addi	s0,sp,16
    800019f8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019fa:	2781                	sext.w	a5,a5
    800019fc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019fe:	0000f517          	auipc	a0,0xf
    80001a02:	19250513          	addi	a0,a0,402 # 80010b90 <cpus>
    80001a06:	953e                	add	a0,a0,a5
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
  push_off();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	1ce080e7          	jalr	462(ra) # 80000be6 <push_off>
    80001a20:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
    80001a26:	0000f717          	auipc	a4,0xf
    80001a2a:	13a70713          	addi	a4,a4,314 # 80010b60 <pid_lock>
    80001a2e:	97ba                	add	a5,a5,a4
    80001a30:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	254080e7          	jalr	596(ra) # 80000c86 <pop_off>
  return p;
}
    80001a3a:	8526                	mv	a0,s1
    80001a3c:	60e2                	ld	ra,24(sp)
    80001a3e:	6442                	ld	s0,16(sp)
    80001a40:	64a2                	ld	s1,8(sp)
    80001a42:	6105                	addi	sp,sp,32
    80001a44:	8082                	ret

0000000080001a46 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a46:	1141                	addi	sp,sp,-16
    80001a48:	e406                	sd	ra,8(sp)
    80001a4a:	e022                	sd	s0,0(sp)
    80001a4c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	fc0080e7          	jalr	-64(ra) # 80001a0e <myproc>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	290080e7          	jalr	656(ra) # 80000ce6 <release>

  if (first) {
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	df27a783          	lw	a5,-526(a5) # 80008850 <first.1688>
    80001a66:	eb89                	bnez	a5,80001a78 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a68:	00001097          	auipc	ra,0x1
    80001a6c:	d26080e7          	jalr	-730(ra) # 8000278e <usertrapret>
}
    80001a70:	60a2                	ld	ra,8(sp)
    80001a72:	6402                	ld	s0,0(sp)
    80001a74:	0141                	addi	sp,sp,16
    80001a76:	8082                	ret
    first = 0;
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	dc07ac23          	sw	zero,-552(a5) # 80008850 <first.1688>
    fsinit(ROOTDEV);
    80001a80:	4505                	li	a0,1
    80001a82:	00002097          	auipc	ra,0x2
    80001a86:	ad2080e7          	jalr	-1326(ra) # 80003554 <fsinit>
    80001a8a:	bff9                	j	80001a68 <forkret+0x22>

0000000080001a8c <allocpid>:
{
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a98:	0000f917          	auipc	s2,0xf
    80001a9c:	0c890913          	addi	s2,s2,200 # 80010b60 <pid_lock>
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	190080e7          	jalr	400(ra) # 80000c32 <acquire>
  pid = nextpid;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	daa78793          	addi	a5,a5,-598 # 80008854 <nextpid>
    80001ab2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ab4:	0014871b          	addiw	a4,s1,1
    80001ab8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	22a080e7          	jalr	554(ra) # 80000ce6 <release>
}
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	60e2                	ld	ra,24(sp)
    80001ac8:	6442                	ld	s0,16(sp)
    80001aca:	64a2                	ld	s1,8(sp)
    80001acc:	6902                	ld	s2,0(sp)
    80001ace:	6105                	addi	sp,sp,32
    80001ad0:	8082                	ret

0000000080001ad2 <proc_pagetable>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	e04a                	sd	s2,0(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	8ac080e7          	jalr	-1876(ra) # 8000138c <uvmcreate>
    80001ae8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aea:	c121                	beqz	a0,80001b2a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aec:	4729                	li	a4,10
    80001aee:	00005697          	auipc	a3,0x5
    80001af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80001af6:	6605                	lui	a2,0x1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	602080e7          	jalr	1538(ra) # 80001102 <mappages>
    80001b08:	02054863          	bltz	a0,80001b38 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b0c:	4719                	li	a4,6
    80001b0e:	05893683          	ld	a3,88(s2)
    80001b12:	6605                	lui	a2,0x1
    80001b14:	020005b7          	lui	a1,0x2000
    80001b18:	15fd                	addi	a1,a1,-1
    80001b1a:	05b6                	slli	a1,a1,0xd
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	5e4080e7          	jalr	1508(ra) # 80001102 <mappages>
    80001b26:	02054163          	bltz	a0,80001b48 <proc_pagetable+0x76>
}
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6902                	ld	s2,0(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret
    uvmfree(pagetable, 0);
    80001b38:	4581                	li	a1,0
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	a54080e7          	jalr	-1452(ra) # 80001590 <uvmfree>
    return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	b7d5                	j	80001b2a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b48:	4681                	li	a3,0
    80001b4a:	4605                	li	a2,1
    80001b4c:	040005b7          	lui	a1,0x4000
    80001b50:	15fd                	addi	a1,a1,-1
    80001b52:	05b2                	slli	a1,a1,0xc
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	772080e7          	jalr	1906(ra) # 800012c8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b5e:	4581                	li	a1,0
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	a2e080e7          	jalr	-1490(ra) # 80001590 <uvmfree>
    return 0;
    80001b6a:	4481                	li	s1,0
    80001b6c:	bf7d                	j	80001b2a <proc_pagetable+0x58>

0000000080001b6e <proc_freepagetable>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
    80001b7a:	84aa                	mv	s1,a0
    80001b7c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7e:	4681                	li	a3,0
    80001b80:	4605                	li	a2,1
    80001b82:	040005b7          	lui	a1,0x4000
    80001b86:	15fd                	addi	a1,a1,-1
    80001b88:	05b2                	slli	a1,a1,0xc
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	73e080e7          	jalr	1854(ra) # 800012c8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b92:	4681                	li	a3,0
    80001b94:	4605                	li	a2,1
    80001b96:	020005b7          	lui	a1,0x2000
    80001b9a:	15fd                	addi	a1,a1,-1
    80001b9c:	05b6                	slli	a1,a1,0xd
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	728080e7          	jalr	1832(ra) # 800012c8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8526                	mv	a0,s1
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	9e4080e7          	jalr	-1564(ra) # 80001590 <uvmfree>
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <freeproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	1000                	addi	s0,sp,32
    80001bca:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bcc:	6d28                	ld	a0,88(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e2e080e7          	jalr	-466(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bdc:	68a8                	ld	a0,80(s1)
    80001bde:	c511                	beqz	a0,80001bea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001be0:	64ac                	ld	a1,72(s1)
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	f8c080e7          	jalr	-116(ra) # 80001b6e <proc_freepagetable>
  p->pagetable = 0;
    80001bea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bfa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c02:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c06:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <allocproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	0000f497          	auipc	s1,0xf
    80001c28:	36c48493          	addi	s1,s1,876 # 80010f90 <proc>
    80001c2c:	00015917          	auipc	s2,0x15
    80001c30:	f6490913          	addi	s2,s2,-156 # 80016b90 <tickslock>
    acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	ffc080e7          	jalr	-4(ra) # 80000c32 <acquire>
    if(p->state == UNUSED) {
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
      release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	0a2080e7          	jalr	162(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4c:	17048493          	addi	s1,s1,368
    80001c50:	ff2492e3          	bne	s1,s2,80001c34 <allocproc+0x1c>
  return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	a899                	j	80001cac <allocproc+0x94>
  p->pid = allocpid();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e34080e7          	jalr	-460(ra) # 80001a8c <allocpid>
    80001c60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c62:	4785                	li	a5,1
    80001c64:	cc9c                	sw	a5,24(s1)
  p->syscall_count = 0;
    80001c66:	1604a423          	sw	zero,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	e90080e7          	jalr	-368(ra) # 80000afa <kalloc>
    80001c72:	892a                	mv	s2,a0
    80001c74:	eca8                	sd	a0,88(s1)
    80001c76:	c131                	beqz	a0,80001cba <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	e58080e7          	jalr	-424(ra) # 80001ad2 <proc_pagetable>
    80001c82:	892a                	mv	s2,a0
    80001c84:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c86:	c531                	beqz	a0,80001cd2 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c88:	07000613          	li	a2,112
    80001c8c:	4581                	li	a1,0
    80001c8e:	06048513          	addi	a0,s1,96
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	09c080e7          	jalr	156(ra) # 80000d2e <memset>
  p->context.ra = (uint64)forkret;
    80001c9a:	00000797          	auipc	a5,0x0
    80001c9e:	dac78793          	addi	a5,a5,-596 # 80001a46 <forkret>
    80001ca2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ca4:	60bc                	ld	a5,64(s1)
    80001ca6:	6705                	lui	a4,0x1
    80001ca8:	97ba                	add	a5,a5,a4
    80001caa:	f4bc                	sd	a5,104(s1)
}
    80001cac:	8526                	mv	a0,s1
    80001cae:	60e2                	ld	ra,24(sp)
    80001cb0:	6442                	ld	s0,16(sp)
    80001cb2:	64a2                	ld	s1,8(sp)
    80001cb4:	6902                	ld	s2,0(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	f04080e7          	jalr	-252(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	020080e7          	jalr	32(ra) # 80000ce6 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	bff1                	j	80001cac <allocproc+0x94>
    freeproc(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	eec080e7          	jalr	-276(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	008080e7          	jalr	8(ra) # 80000ce6 <release>
    return 0;
    80001ce6:	84ca                	mv	s1,s2
    80001ce8:	b7d1                	j	80001cac <allocproc+0x94>

0000000080001cea <userinit>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	f24080e7          	jalr	-220(ra) # 80001c18 <allocproc>
    80001cfc:	84aa                	mv	s1,a0
  initproc = p;
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	bea7b523          	sd	a0,-1046(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d06:	03400613          	li	a2,52
    80001d0a:	00007597          	auipc	a1,0x7
    80001d0e:	b5658593          	addi	a1,a1,-1194 # 80008860 <initcode>
    80001d12:	6928                	ld	a0,80(a0)
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	6a6080e7          	jalr	1702(ra) # 800013ba <uvmfirst>
  p->sz = PGSIZE;
    80001d1c:	6785                	lui	a5,0x1
    80001d1e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d20:	6cb8                	ld	a4,88(s1)
    80001d22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d26:	6cb8                	ld	a4,88(s1)
    80001d28:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d2a:	4641                	li	a2,16
    80001d2c:	00006597          	auipc	a1,0x6
    80001d30:	4d458593          	addi	a1,a1,1236 # 80008200 <digits+0x1c0>
    80001d34:	15848513          	addi	a0,s1,344
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	148080e7          	jalr	328(ra) # 80000e80 <safestrcpy>
  p->cwd = namei("/");
    80001d40:	00006517          	auipc	a0,0x6
    80001d44:	4d050513          	addi	a0,a0,1232 # 80008210 <digits+0x1d0>
    80001d48:	00002097          	auipc	ra,0x2
    80001d4c:	22e080e7          	jalr	558(ra) # 80003f76 <namei>
    80001d50:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d54:	478d                	li	a5,3
    80001d56:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	f8c080e7          	jalr	-116(ra) # 80000ce6 <release>
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret

0000000080001d6c <growproc>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	e04a                	sd	s2,0(sp)
    80001d76:	1000                	addi	s0,sp,32
    80001d78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c94080e7          	jalr	-876(ra) # 80001a0e <myproc>
    80001d82:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d84:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d86:	01204c63          	bgtz	s2,80001d9e <growproc+0x32>
  } else if(n < 0){
    80001d8a:	02094663          	bltz	s2,80001db6 <growproc+0x4a>
  p->sz = sz;
    80001d8e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d90:	4501                	li	a0,0
}
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6902                	ld	s2,0(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d9e:	4691                	li	a3,4
    80001da0:	00b90633          	add	a2,s2,a1
    80001da4:	6928                	ld	a0,80(a0)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	6ce080e7          	jalr	1742(ra) # 80001474 <uvmalloc>
    80001dae:	85aa                	mv	a1,a0
    80001db0:	fd79                	bnez	a0,80001d8e <growproc+0x22>
      return -1;
    80001db2:	557d                	li	a0,-1
    80001db4:	bff9                	j	80001d92 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db6:	00b90633          	add	a2,s2,a1
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	670080e7          	jalr	1648(ra) # 8000142c <uvmdealloc>
    80001dc4:	85aa                	mv	a1,a0
    80001dc6:	b7e1                	j	80001d8e <growproc+0x22>

0000000080001dc8 <fork>:
{
    80001dc8:	7179                	addi	sp,sp,-48
    80001dca:	f406                	sd	ra,40(sp)
    80001dcc:	f022                	sd	s0,32(sp)
    80001dce:	ec26                	sd	s1,24(sp)
    80001dd0:	e84a                	sd	s2,16(sp)
    80001dd2:	e44e                	sd	s3,8(sp)
    80001dd4:	e052                	sd	s4,0(sp)
    80001dd6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	c36080e7          	jalr	-970(ra) # 80001a0e <myproc>
    80001de0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	e36080e7          	jalr	-458(ra) # 80001c18 <allocproc>
    80001dea:	10050b63          	beqz	a0,80001f00 <fork+0x138>
    80001dee:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df0:	04893603          	ld	a2,72(s2)
    80001df4:	692c                	ld	a1,80(a0)
    80001df6:	05093503          	ld	a0,80(s2)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	7ce080e7          	jalr	1998(ra) # 800015c8 <uvmcopy>
    80001e02:	04054663          	bltz	a0,80001e4e <fork+0x86>
  np->sz = p->sz;
    80001e06:	04893783          	ld	a5,72(s2)
    80001e0a:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e0e:	05893683          	ld	a3,88(s2)
    80001e12:	87b6                	mv	a5,a3
    80001e14:	0589b703          	ld	a4,88(s3)
    80001e18:	12068693          	addi	a3,a3,288
    80001e1c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e20:	6788                	ld	a0,8(a5)
    80001e22:	6b8c                	ld	a1,16(a5)
    80001e24:	6f90                	ld	a2,24(a5)
    80001e26:	01073023          	sd	a6,0(a4)
    80001e2a:	e708                	sd	a0,8(a4)
    80001e2c:	eb0c                	sd	a1,16(a4)
    80001e2e:	ef10                	sd	a2,24(a4)
    80001e30:	02078793          	addi	a5,a5,32
    80001e34:	02070713          	addi	a4,a4,32
    80001e38:	fed792e3          	bne	a5,a3,80001e1c <fork+0x54>
  np->trapframe->a0 = 0;
    80001e3c:	0589b783          	ld	a5,88(s3)
    80001e40:	0607b823          	sd	zero,112(a5)
    80001e44:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e48:	15000a13          	li	s4,336
    80001e4c:	a03d                	j	80001e7a <fork+0xb2>
    freeproc(np);
    80001e4e:	854e                	mv	a0,s3
    80001e50:	00000097          	auipc	ra,0x0
    80001e54:	d70080e7          	jalr	-656(ra) # 80001bc0 <freeproc>
    release(&np->lock);
    80001e58:	854e                	mv	a0,s3
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e8c080e7          	jalr	-372(ra) # 80000ce6 <release>
    return -1;
    80001e62:	5a7d                	li	s4,-1
    80001e64:	a069                	j	80001eee <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e66:	00002097          	auipc	ra,0x2
    80001e6a:	7a6080e7          	jalr	1958(ra) # 8000460c <filedup>
    80001e6e:	009987b3          	add	a5,s3,s1
    80001e72:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e74:	04a1                	addi	s1,s1,8
    80001e76:	01448763          	beq	s1,s4,80001e84 <fork+0xbc>
    if(p->ofile[i])
    80001e7a:	009907b3          	add	a5,s2,s1
    80001e7e:	6388                	ld	a0,0(a5)
    80001e80:	f17d                	bnez	a0,80001e66 <fork+0x9e>
    80001e82:	bfcd                	j	80001e74 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e84:	15093503          	ld	a0,336(s2)
    80001e88:	00002097          	auipc	ra,0x2
    80001e8c:	90a080e7          	jalr	-1782(ra) # 80003792 <idup>
    80001e90:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e94:	4641                	li	a2,16
    80001e96:	15890593          	addi	a1,s2,344
    80001e9a:	15898513          	addi	a0,s3,344
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	fe2080e7          	jalr	-30(ra) # 80000e80 <safestrcpy>
  pid = np->pid;
    80001ea6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eaa:	854e                	mv	a0,s3
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	e3a080e7          	jalr	-454(ra) # 80000ce6 <release>
  acquire(&wait_lock);
    80001eb4:	0000f497          	auipc	s1,0xf
    80001eb8:	cc448493          	addi	s1,s1,-828 # 80010b78 <wait_lock>
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d74080e7          	jalr	-652(ra) # 80000c32 <acquire>
  np->parent = p;
    80001ec6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	e1a080e7          	jalr	-486(ra) # 80000ce6 <release>
  acquire(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	d5c080e7          	jalr	-676(ra) # 80000c32 <acquire>
  np->state = RUNNABLE;
    80001ede:	478d                	li	a5,3
    80001ee0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee4:	854e                	mv	a0,s3
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	e00080e7          	jalr	-512(ra) # 80000ce6 <release>
}
    80001eee:	8552                	mv	a0,s4
    80001ef0:	70a2                	ld	ra,40(sp)
    80001ef2:	7402                	ld	s0,32(sp)
    80001ef4:	64e2                	ld	s1,24(sp)
    80001ef6:	6942                	ld	s2,16(sp)
    80001ef8:	69a2                	ld	s3,8(sp)
    80001efa:	6a02                	ld	s4,0(sp)
    80001efc:	6145                	addi	sp,sp,48
    80001efe:	8082                	ret
    return -1;
    80001f00:	5a7d                	li	s4,-1
    80001f02:	b7f5                	j	80001eee <fork+0x126>

0000000080001f04 <scheduler>:
{
    80001f04:	7139                	addi	sp,sp,-64
    80001f06:	fc06                	sd	ra,56(sp)
    80001f08:	f822                	sd	s0,48(sp)
    80001f0a:	f426                	sd	s1,40(sp)
    80001f0c:	f04a                	sd	s2,32(sp)
    80001f0e:	ec4e                	sd	s3,24(sp)
    80001f10:	e852                	sd	s4,16(sp)
    80001f12:	e456                	sd	s5,8(sp)
    80001f14:	e05a                	sd	s6,0(sp)
    80001f16:	0080                	addi	s0,sp,64
    80001f18:	8792                	mv	a5,tp
  int id = r_tp();
    80001f1a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f1c:	00779a93          	slli	s5,a5,0x7
    80001f20:	0000f717          	auipc	a4,0xf
    80001f24:	c4070713          	addi	a4,a4,-960 # 80010b60 <pid_lock>
    80001f28:	9756                	add	a4,a4,s5
    80001f2a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f2e:	0000f717          	auipc	a4,0xf
    80001f32:	c6a70713          	addi	a4,a4,-918 # 80010b98 <cpus+0x8>
    80001f36:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f38:	498d                	li	s3,3
        p->state = RUNNING;
    80001f3a:	4b11                	li	s6,4
        c->proc = p;
    80001f3c:	079e                	slli	a5,a5,0x7
    80001f3e:	0000fa17          	auipc	s4,0xf
    80001f42:	c22a0a13          	addi	s4,s4,-990 # 80010b60 <pid_lock>
    80001f46:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f48:	00015917          	auipc	s2,0x15
    80001f4c:	c4890913          	addi	s2,s2,-952 # 80016b90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f58:	10079073          	csrw	sstatus,a5
    80001f5c:	0000f497          	auipc	s1,0xf
    80001f60:	03448493          	addi	s1,s1,52 # 80010f90 <proc>
    80001f64:	a03d                	j	80001f92 <scheduler+0x8e>
        p->state = RUNNING;
    80001f66:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f6a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f6e:	06048593          	addi	a1,s1,96
    80001f72:	8556                	mv	a0,s5
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	770080e7          	jalr	1904(ra) # 800026e4 <swtch>
        c->proc = 0;
    80001f7c:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	d64080e7          	jalr	-668(ra) # 80000ce6 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8a:	17048493          	addi	s1,s1,368
    80001f8e:	fd2481e3          	beq	s1,s2,80001f50 <scheduler+0x4c>
      acquire(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	c9e080e7          	jalr	-866(ra) # 80000c32 <acquire>
      if(p->state == RUNNABLE) {
    80001f9c:	4c9c                	lw	a5,24(s1)
    80001f9e:	ff3791e3          	bne	a5,s3,80001f80 <scheduler+0x7c>
    80001fa2:	b7d1                	j	80001f66 <scheduler+0x62>

0000000080001fa4 <sched>:
{
    80001fa4:	7179                	addi	sp,sp,-48
    80001fa6:	f406                	sd	ra,40(sp)
    80001fa8:	f022                	sd	s0,32(sp)
    80001faa:	ec26                	sd	s1,24(sp)
    80001fac:	e84a                	sd	s2,16(sp)
    80001fae:	e44e                	sd	s3,8(sp)
    80001fb0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb2:	00000097          	auipc	ra,0x0
    80001fb6:	a5c080e7          	jalr	-1444(ra) # 80001a0e <myproc>
    80001fba:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	bfc080e7          	jalr	-1028(ra) # 80000bb8 <holding>
    80001fc4:	c93d                	beqz	a0,8000203a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	0000f717          	auipc	a4,0xf
    80001fd0:	b9470713          	addi	a4,a4,-1132 # 80010b60 <pid_lock>
    80001fd4:	97ba                	add	a5,a5,a4
    80001fd6:	0a87a703          	lw	a4,168(a5)
    80001fda:	4785                	li	a5,1
    80001fdc:	06f71763          	bne	a4,a5,8000204a <sched+0xa6>
  if(p->state == RUNNING)
    80001fe0:	4c98                	lw	a4,24(s1)
    80001fe2:	4791                	li	a5,4
    80001fe4:	06f70b63          	beq	a4,a5,8000205a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fec:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fee:	efb5                	bnez	a5,8000206a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff2:	0000f917          	auipc	s2,0xf
    80001ff6:	b6e90913          	addi	s2,s2,-1170 # 80010b60 <pid_lock>
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	97ca                	add	a5,a5,s2
    80002000:	0ac7a983          	lw	s3,172(a5)
    80002004:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002006:	2781                	sext.w	a5,a5
    80002008:	079e                	slli	a5,a5,0x7
    8000200a:	0000f597          	auipc	a1,0xf
    8000200e:	b8e58593          	addi	a1,a1,-1138 # 80010b98 <cpus+0x8>
    80002012:	95be                	add	a1,a1,a5
    80002014:	06048513          	addi	a0,s1,96
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	6cc080e7          	jalr	1740(ra) # 800026e4 <swtch>
    80002020:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002022:	2781                	sext.w	a5,a5
    80002024:	079e                	slli	a5,a5,0x7
    80002026:	97ca                	add	a5,a5,s2
    80002028:	0b37a623          	sw	s3,172(a5)
}
    8000202c:	70a2                	ld	ra,40(sp)
    8000202e:	7402                	ld	s0,32(sp)
    80002030:	64e2                	ld	s1,24(sp)
    80002032:	6942                	ld	s2,16(sp)
    80002034:	69a2                	ld	s3,8(sp)
    80002036:	6145                	addi	sp,sp,48
    80002038:	8082                	ret
    panic("sched p->lock");
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1de50513          	addi	a0,a0,478 # 80008218 <digits+0x1d8>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	502080e7          	jalr	1282(ra) # 80000544 <panic>
    panic("sched locks");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	1de50513          	addi	a0,a0,478 # 80008228 <digits+0x1e8>
    80002052:	ffffe097          	auipc	ra,0xffffe
    80002056:	4f2080e7          	jalr	1266(ra) # 80000544 <panic>
    panic("sched running");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	1de50513          	addi	a0,a0,478 # 80008238 <digits+0x1f8>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4e2080e7          	jalr	1250(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000206a:	00006517          	auipc	a0,0x6
    8000206e:	1de50513          	addi	a0,a0,478 # 80008248 <digits+0x208>
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	4d2080e7          	jalr	1234(ra) # 80000544 <panic>

000000008000207a <yield>:
{
    8000207a:	1101                	addi	sp,sp,-32
    8000207c:	ec06                	sd	ra,24(sp)
    8000207e:	e822                	sd	s0,16(sp)
    80002080:	e426                	sd	s1,8(sp)
    80002082:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	98a080e7          	jalr	-1654(ra) # 80001a0e <myproc>
    8000208c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	ba4080e7          	jalr	-1116(ra) # 80000c32 <acquire>
  p->state = RUNNABLE;
    80002096:	478d                	li	a5,3
    80002098:	cc9c                	sw	a5,24(s1)
  sched();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	f0a080e7          	jalr	-246(ra) # 80001fa4 <sched>
  release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	c42080e7          	jalr	-958(ra) # 80000ce6 <release>
}
    800020ac:	60e2                	ld	ra,24(sp)
    800020ae:	6442                	ld	s0,16(sp)
    800020b0:	64a2                	ld	s1,8(sp)
    800020b2:	6105                	addi	sp,sp,32
    800020b4:	8082                	ret

00000000800020b6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020b6:	7179                	addi	sp,sp,-48
    800020b8:	f406                	sd	ra,40(sp)
    800020ba:	f022                	sd	s0,32(sp)
    800020bc:	ec26                	sd	s1,24(sp)
    800020be:	e84a                	sd	s2,16(sp)
    800020c0:	e44e                	sd	s3,8(sp)
    800020c2:	1800                	addi	s0,sp,48
    800020c4:	89aa                	mv	s3,a0
    800020c6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	946080e7          	jalr	-1722(ra) # 80001a0e <myproc>
    800020d0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b60080e7          	jalr	-1184(ra) # 80000c32 <acquire>
  release(lk);
    800020da:	854a                	mv	a0,s2
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	c0a080e7          	jalr	-1014(ra) # 80000ce6 <release>

  // Go to sleep.
  p->chan = chan;
    800020e4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e8:	4789                	li	a5,2
    800020ea:	cc9c                	sw	a5,24(s1)

  sched();
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	eb8080e7          	jalr	-328(ra) # 80001fa4 <sched>

  // Tidy up.
  p->chan = 0;
    800020f4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	bec080e7          	jalr	-1044(ra) # 80000ce6 <release>
  acquire(lk);
    80002102:	854a                	mv	a0,s2
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b2e080e7          	jalr	-1234(ra) # 80000c32 <acquire>
}
    8000210c:	70a2                	ld	ra,40(sp)
    8000210e:	7402                	ld	s0,32(sp)
    80002110:	64e2                	ld	s1,24(sp)
    80002112:	6942                	ld	s2,16(sp)
    80002114:	69a2                	ld	s3,8(sp)
    80002116:	6145                	addi	sp,sp,48
    80002118:	8082                	ret

000000008000211a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000211a:	7139                	addi	sp,sp,-64
    8000211c:	fc06                	sd	ra,56(sp)
    8000211e:	f822                	sd	s0,48(sp)
    80002120:	f426                	sd	s1,40(sp)
    80002122:	f04a                	sd	s2,32(sp)
    80002124:	ec4e                	sd	s3,24(sp)
    80002126:	e852                	sd	s4,16(sp)
    80002128:	e456                	sd	s5,8(sp)
    8000212a:	0080                	addi	s0,sp,64
    8000212c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000212e:	0000f497          	auipc	s1,0xf
    80002132:	e6248493          	addi	s1,s1,-414 # 80010f90 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002136:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002138:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000213a:	00015917          	auipc	s2,0x15
    8000213e:	a5690913          	addi	s2,s2,-1450 # 80016b90 <tickslock>
    80002142:	a821                	j	8000215a <wakeup+0x40>
        p->state = RUNNABLE;
    80002144:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b9c080e7          	jalr	-1124(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002152:	17048493          	addi	s1,s1,368
    80002156:	03248463          	beq	s1,s2,8000217e <wakeup+0x64>
    if(p != myproc()){
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	8b4080e7          	jalr	-1868(ra) # 80001a0e <myproc>
    80002162:	fea488e3          	beq	s1,a0,80002152 <wakeup+0x38>
      acquire(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	aca080e7          	jalr	-1334(ra) # 80000c32 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002170:	4c9c                	lw	a5,24(s1)
    80002172:	fd379be3          	bne	a5,s3,80002148 <wakeup+0x2e>
    80002176:	709c                	ld	a5,32(s1)
    80002178:	fd4798e3          	bne	a5,s4,80002148 <wakeup+0x2e>
    8000217c:	b7e1                	j	80002144 <wakeup+0x2a>
    }
  }
}
    8000217e:	70e2                	ld	ra,56(sp)
    80002180:	7442                	ld	s0,48(sp)
    80002182:	74a2                	ld	s1,40(sp)
    80002184:	7902                	ld	s2,32(sp)
    80002186:	69e2                	ld	s3,24(sp)
    80002188:	6a42                	ld	s4,16(sp)
    8000218a:	6aa2                	ld	s5,8(sp)
    8000218c:	6121                	addi	sp,sp,64
    8000218e:	8082                	ret

0000000080002190 <reparent>:
{
    80002190:	7179                	addi	sp,sp,-48
    80002192:	f406                	sd	ra,40(sp)
    80002194:	f022                	sd	s0,32(sp)
    80002196:	ec26                	sd	s1,24(sp)
    80002198:	e84a                	sd	s2,16(sp)
    8000219a:	e44e                	sd	s3,8(sp)
    8000219c:	e052                	sd	s4,0(sp)
    8000219e:	1800                	addi	s0,sp,48
    800021a0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021a2:	0000f497          	auipc	s1,0xf
    800021a6:	dee48493          	addi	s1,s1,-530 # 80010f90 <proc>
      pp->parent = initproc;
    800021aa:	00006a17          	auipc	s4,0x6
    800021ae:	73ea0a13          	addi	s4,s4,1854 # 800088e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b2:	00015997          	auipc	s3,0x15
    800021b6:	9de98993          	addi	s3,s3,-1570 # 80016b90 <tickslock>
    800021ba:	a029                	j	800021c4 <reparent+0x34>
    800021bc:	17048493          	addi	s1,s1,368
    800021c0:	01348d63          	beq	s1,s3,800021da <reparent+0x4a>
    if(pp->parent == p){
    800021c4:	7c9c                	ld	a5,56(s1)
    800021c6:	ff279be3          	bne	a5,s2,800021bc <reparent+0x2c>
      pp->parent = initproc;
    800021ca:	000a3503          	ld	a0,0(s4)
    800021ce:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	f4a080e7          	jalr	-182(ra) # 8000211a <wakeup>
    800021d8:	b7d5                	j	800021bc <reparent+0x2c>
}
    800021da:	70a2                	ld	ra,40(sp)
    800021dc:	7402                	ld	s0,32(sp)
    800021de:	64e2                	ld	s1,24(sp)
    800021e0:	6942                	ld	s2,16(sp)
    800021e2:	69a2                	ld	s3,8(sp)
    800021e4:	6a02                	ld	s4,0(sp)
    800021e6:	6145                	addi	sp,sp,48
    800021e8:	8082                	ret

00000000800021ea <exit>:
{
    800021ea:	7179                	addi	sp,sp,-48
    800021ec:	f406                	sd	ra,40(sp)
    800021ee:	f022                	sd	s0,32(sp)
    800021f0:	ec26                	sd	s1,24(sp)
    800021f2:	e84a                	sd	s2,16(sp)
    800021f4:	e44e                	sd	s3,8(sp)
    800021f6:	e052                	sd	s4,0(sp)
    800021f8:	1800                	addi	s0,sp,48
    800021fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	812080e7          	jalr	-2030(ra) # 80001a0e <myproc>
    80002204:	89aa                	mv	s3,a0
  if(p == initproc)
    80002206:	00006797          	auipc	a5,0x6
    8000220a:	6e27b783          	ld	a5,1762(a5) # 800088e8 <initproc>
    8000220e:	0d050493          	addi	s1,a0,208
    80002212:	15050913          	addi	s2,a0,336
    80002216:	02a79363          	bne	a5,a0,8000223c <exit+0x52>
    panic("init exiting");
    8000221a:	00006517          	auipc	a0,0x6
    8000221e:	04650513          	addi	a0,a0,70 # 80008260 <digits+0x220>
    80002222:	ffffe097          	auipc	ra,0xffffe
    80002226:	322080e7          	jalr	802(ra) # 80000544 <panic>
      fileclose(f);
    8000222a:	00002097          	auipc	ra,0x2
    8000222e:	434080e7          	jalr	1076(ra) # 8000465e <fileclose>
      p->ofile[fd] = 0;
    80002232:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002236:	04a1                	addi	s1,s1,8
    80002238:	01248563          	beq	s1,s2,80002242 <exit+0x58>
    if(p->ofile[fd]){
    8000223c:	6088                	ld	a0,0(s1)
    8000223e:	f575                	bnez	a0,8000222a <exit+0x40>
    80002240:	bfdd                	j	80002236 <exit+0x4c>
  begin_op();
    80002242:	00002097          	auipc	ra,0x2
    80002246:	f50080e7          	jalr	-176(ra) # 80004192 <begin_op>
  iput(p->cwd);
    8000224a:	1509b503          	ld	a0,336(s3)
    8000224e:	00001097          	auipc	ra,0x1
    80002252:	73c080e7          	jalr	1852(ra) # 8000398a <iput>
  end_op();
    80002256:	00002097          	auipc	ra,0x2
    8000225a:	fbc080e7          	jalr	-68(ra) # 80004212 <end_op>
  p->cwd = 0;
    8000225e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002262:	0000f497          	auipc	s1,0xf
    80002266:	91648493          	addi	s1,s1,-1770 # 80010b78 <wait_lock>
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	9c6080e7          	jalr	-1594(ra) # 80000c32 <acquire>
  reparent(p);
    80002274:	854e                	mv	a0,s3
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	f1a080e7          	jalr	-230(ra) # 80002190 <reparent>
  wakeup(p->parent);
    8000227e:	0389b503          	ld	a0,56(s3)
    80002282:	00000097          	auipc	ra,0x0
    80002286:	e98080e7          	jalr	-360(ra) # 8000211a <wakeup>
  acquire(&p->lock);
    8000228a:	854e                	mv	a0,s3
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	9a6080e7          	jalr	-1626(ra) # 80000c32 <acquire>
  p->xstate = status;
    80002294:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002298:	4795                	li	a5,5
    8000229a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	a46080e7          	jalr	-1466(ra) # 80000ce6 <release>
  sched();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	cfc080e7          	jalr	-772(ra) # 80001fa4 <sched>
  panic("zombie exit");
    800022b0:	00006517          	auipc	a0,0x6
    800022b4:	fc050513          	addi	a0,a0,-64 # 80008270 <digits+0x230>
    800022b8:	ffffe097          	auipc	ra,0xffffe
    800022bc:	28c080e7          	jalr	652(ra) # 80000544 <panic>

00000000800022c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022c0:	7179                	addi	sp,sp,-48
    800022c2:	f406                	sd	ra,40(sp)
    800022c4:	f022                	sd	s0,32(sp)
    800022c6:	ec26                	sd	s1,24(sp)
    800022c8:	e84a                	sd	s2,16(sp)
    800022ca:	e44e                	sd	s3,8(sp)
    800022cc:	1800                	addi	s0,sp,48
    800022ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022d0:	0000f497          	auipc	s1,0xf
    800022d4:	cc048493          	addi	s1,s1,-832 # 80010f90 <proc>
    800022d8:	00015997          	auipc	s3,0x15
    800022dc:	8b898993          	addi	s3,s3,-1864 # 80016b90 <tickslock>
    acquire(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	950080e7          	jalr	-1712(ra) # 80000c32 <acquire>
    if(p->pid == pid){
    800022ea:	589c                	lw	a5,48(s1)
    800022ec:	01278d63          	beq	a5,s2,80002306 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9f4080e7          	jalr	-1548(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022fa:	17048493          	addi	s1,s1,368
    800022fe:	ff3491e3          	bne	s1,s3,800022e0 <kill+0x20>
  }
  return -1;
    80002302:	557d                	li	a0,-1
    80002304:	a829                	j	8000231e <kill+0x5e>
      p->killed = 1;
    80002306:	4785                	li	a5,1
    80002308:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000230a:	4c98                	lw	a4,24(s1)
    8000230c:	4789                	li	a5,2
    8000230e:	00f70f63          	beq	a4,a5,8000232c <kill+0x6c>
      release(&p->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	9d2080e7          	jalr	-1582(ra) # 80000ce6 <release>
      return 0;
    8000231c:	4501                	li	a0,0
}
    8000231e:	70a2                	ld	ra,40(sp)
    80002320:	7402                	ld	s0,32(sp)
    80002322:	64e2                	ld	s1,24(sp)
    80002324:	6942                	ld	s2,16(sp)
    80002326:	69a2                	ld	s3,8(sp)
    80002328:	6145                	addi	sp,sp,48
    8000232a:	8082                	ret
        p->state = RUNNABLE;
    8000232c:	478d                	li	a5,3
    8000232e:	cc9c                	sw	a5,24(s1)
    80002330:	b7cd                	j	80002312 <kill+0x52>

0000000080002332 <setkilled>:

void
setkilled(struct proc *p)
{
    80002332:	1101                	addi	sp,sp,-32
    80002334:	ec06                	sd	ra,24(sp)
    80002336:	e822                	sd	s0,16(sp)
    80002338:	e426                	sd	s1,8(sp)
    8000233a:	1000                	addi	s0,sp,32
    8000233c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	8f4080e7          	jalr	-1804(ra) # 80000c32 <acquire>
  p->killed = 1;
    80002346:	4785                	li	a5,1
    80002348:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	99a080e7          	jalr	-1638(ra) # 80000ce6 <release>
}
    80002354:	60e2                	ld	ra,24(sp)
    80002356:	6442                	ld	s0,16(sp)
    80002358:	64a2                	ld	s1,8(sp)
    8000235a:	6105                	addi	sp,sp,32
    8000235c:	8082                	ret

000000008000235e <killed>:

int
killed(struct proc *p)
{
    8000235e:	1101                	addi	sp,sp,-32
    80002360:	ec06                	sd	ra,24(sp)
    80002362:	e822                	sd	s0,16(sp)
    80002364:	e426                	sd	s1,8(sp)
    80002366:	e04a                	sd	s2,0(sp)
    80002368:	1000                	addi	s0,sp,32
    8000236a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	8c6080e7          	jalr	-1850(ra) # 80000c32 <acquire>
  k = p->killed;
    80002374:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	96c080e7          	jalr	-1684(ra) # 80000ce6 <release>
  return k;
}
    80002382:	854a                	mv	a0,s2
    80002384:	60e2                	ld	ra,24(sp)
    80002386:	6442                	ld	s0,16(sp)
    80002388:	64a2                	ld	s1,8(sp)
    8000238a:	6902                	ld	s2,0(sp)
    8000238c:	6105                	addi	sp,sp,32
    8000238e:	8082                	ret

0000000080002390 <wait>:
{
    80002390:	715d                	addi	sp,sp,-80
    80002392:	e486                	sd	ra,72(sp)
    80002394:	e0a2                	sd	s0,64(sp)
    80002396:	fc26                	sd	s1,56(sp)
    80002398:	f84a                	sd	s2,48(sp)
    8000239a:	f44e                	sd	s3,40(sp)
    8000239c:	f052                	sd	s4,32(sp)
    8000239e:	ec56                	sd	s5,24(sp)
    800023a0:	e85a                	sd	s6,16(sp)
    800023a2:	e45e                	sd	s7,8(sp)
    800023a4:	e062                	sd	s8,0(sp)
    800023a6:	0880                	addi	s0,sp,80
    800023a8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	664080e7          	jalr	1636(ra) # 80001a0e <myproc>
    800023b2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023b4:	0000e517          	auipc	a0,0xe
    800023b8:	7c450513          	addi	a0,a0,1988 # 80010b78 <wait_lock>
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	876080e7          	jalr	-1930(ra) # 80000c32 <acquire>
    havekids = 0;
    800023c4:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023c6:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023c8:	00014997          	auipc	s3,0x14
    800023cc:	7c898993          	addi	s3,s3,1992 # 80016b90 <tickslock>
        havekids = 1;
    800023d0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023d2:	0000ec17          	auipc	s8,0xe
    800023d6:	7a6c0c13          	addi	s8,s8,1958 # 80010b78 <wait_lock>
    havekids = 0;
    800023da:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023dc:	0000f497          	auipc	s1,0xf
    800023e0:	bb448493          	addi	s1,s1,-1100 # 80010f90 <proc>
    800023e4:	a0bd                	j	80002452 <wait+0xc2>
          pid = pp->pid;
    800023e6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023ea:	000b0e63          	beqz	s6,80002406 <wait+0x76>
    800023ee:	4691                	li	a3,4
    800023f0:	02c48613          	addi	a2,s1,44
    800023f4:	85da                	mv	a1,s6
    800023f6:	05093503          	ld	a0,80(s2)
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	2d2080e7          	jalr	722(ra) # 800016cc <copyout>
    80002402:	02054563          	bltz	a0,8000242c <wait+0x9c>
          freeproc(pp);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	7b8080e7          	jalr	1976(ra) # 80001bc0 <freeproc>
          release(&pp->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	8d4080e7          	jalr	-1836(ra) # 80000ce6 <release>
          release(&wait_lock);
    8000241a:	0000e517          	auipc	a0,0xe
    8000241e:	75e50513          	addi	a0,a0,1886 # 80010b78 <wait_lock>
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	8c4080e7          	jalr	-1852(ra) # 80000ce6 <release>
          return pid;
    8000242a:	a0b5                	j	80002496 <wait+0x106>
            release(&pp->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	8b8080e7          	jalr	-1864(ra) # 80000ce6 <release>
            release(&wait_lock);
    80002436:	0000e517          	auipc	a0,0xe
    8000243a:	74250513          	addi	a0,a0,1858 # 80010b78 <wait_lock>
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	8a8080e7          	jalr	-1880(ra) # 80000ce6 <release>
            return -1;
    80002446:	59fd                	li	s3,-1
    80002448:	a0b9                	j	80002496 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000244a:	17048493          	addi	s1,s1,368
    8000244e:	03348463          	beq	s1,s3,80002476 <wait+0xe6>
      if(pp->parent == p){
    80002452:	7c9c                	ld	a5,56(s1)
    80002454:	ff279be3          	bne	a5,s2,8000244a <wait+0xba>
        acquire(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	7d8080e7          	jalr	2008(ra) # 80000c32 <acquire>
        if(pp->state == ZOMBIE){
    80002462:	4c9c                	lw	a5,24(s1)
    80002464:	f94781e3          	beq	a5,s4,800023e6 <wait+0x56>
        release(&pp->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	87c080e7          	jalr	-1924(ra) # 80000ce6 <release>
        havekids = 1;
    80002472:	8756                	mv	a4,s5
    80002474:	bfd9                	j	8000244a <wait+0xba>
    if(!havekids || killed(p)){
    80002476:	c719                	beqz	a4,80002484 <wait+0xf4>
    80002478:	854a                	mv	a0,s2
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	ee4080e7          	jalr	-284(ra) # 8000235e <killed>
    80002482:	c51d                	beqz	a0,800024b0 <wait+0x120>
      release(&wait_lock);
    80002484:	0000e517          	auipc	a0,0xe
    80002488:	6f450513          	addi	a0,a0,1780 # 80010b78 <wait_lock>
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	85a080e7          	jalr	-1958(ra) # 80000ce6 <release>
      return -1;
    80002494:	59fd                	li	s3,-1
}
    80002496:	854e                	mv	a0,s3
    80002498:	60a6                	ld	ra,72(sp)
    8000249a:	6406                	ld	s0,64(sp)
    8000249c:	74e2                	ld	s1,56(sp)
    8000249e:	7942                	ld	s2,48(sp)
    800024a0:	79a2                	ld	s3,40(sp)
    800024a2:	7a02                	ld	s4,32(sp)
    800024a4:	6ae2                	ld	s5,24(sp)
    800024a6:	6b42                	ld	s6,16(sp)
    800024a8:	6ba2                	ld	s7,8(sp)
    800024aa:	6c02                	ld	s8,0(sp)
    800024ac:	6161                	addi	sp,sp,80
    800024ae:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024b0:	85e2                	mv	a1,s8
    800024b2:	854a                	mv	a0,s2
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	c02080e7          	jalr	-1022(ra) # 800020b6 <sleep>
    havekids = 0;
    800024bc:	bf39                	j	800023da <wait+0x4a>

00000000800024be <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	84aa                	mv	s1,a0
    800024d0:	892e                	mv	s2,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	538080e7          	jalr	1336(ra) # 80001a0e <myproc>
  if(user_dst){
    800024de:	c08d                	beqz	s1,80002500 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6928                	ld	a0,80(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	1e4080e7          	jalr	484(ra) # 800016cc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove((char *)dst, src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	886080e7          	jalr	-1914(ra) # 80000d8e <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyout+0x32>

0000000080002514 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	e052                	sd	s4,0(sp)
    80002522:	1800                	addi	s0,sp,48
    80002524:	892a                	mv	s2,a0
    80002526:	84ae                	mv	s1,a1
    80002528:	89b2                	mv	s3,a2
    8000252a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	4e2080e7          	jalr	1250(ra) # 80001a0e <myproc>
  if(user_src){
    80002534:	c08d                	beqz	s1,80002556 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002536:	86d2                	mv	a3,s4
    80002538:	864e                	mv	a2,s3
    8000253a:	85ca                	mv	a1,s2
    8000253c:	6928                	ld	a0,80(a0)
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	21a080e7          	jalr	538(ra) # 80001758 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002546:	70a2                	ld	ra,40(sp)
    80002548:	7402                	ld	s0,32(sp)
    8000254a:	64e2                	ld	s1,24(sp)
    8000254c:	6942                	ld	s2,16(sp)
    8000254e:	69a2                	ld	s3,8(sp)
    80002550:	6a02                	ld	s4,0(sp)
    80002552:	6145                	addi	sp,sp,48
    80002554:	8082                	ret
    memmove(dst, (char*)src, len);
    80002556:	000a061b          	sext.w	a2,s4
    8000255a:	85ce                	mv	a1,s3
    8000255c:	854a                	mv	a0,s2
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	830080e7          	jalr	-2000(ra) # 80000d8e <memmove>
    return 0;
    80002566:	8526                	mv	a0,s1
    80002568:	bff9                	j	80002546 <either_copyin+0x32>

000000008000256a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256a:	715d                	addi	sp,sp,-80
    8000256c:	e486                	sd	ra,72(sp)
    8000256e:	e0a2                	sd	s0,64(sp)
    80002570:	fc26                	sd	s1,56(sp)
    80002572:	f84a                	sd	s2,48(sp)
    80002574:	f44e                	sd	s3,40(sp)
    80002576:	f052                	sd	s4,32(sp)
    80002578:	ec56                	sd	s5,24(sp)
    8000257a:	e85a                	sd	s6,16(sp)
    8000257c:	e45e                	sd	s7,8(sp)
    8000257e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002580:	00006517          	auipc	a0,0x6
    80002584:	b4850513          	addi	a0,a0,-1208 # 800080c8 <digits+0x88>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	006080e7          	jalr	6(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	b5848493          	addi	s1,s1,-1192 # 800110e8 <proc+0x158>
    80002598:	00014917          	auipc	s2,0x14
    8000259c:	75090913          	addi	s2,s2,1872 # 80016ce8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a2:	00006997          	auipc	s3,0x6
    800025a6:	cde98993          	addi	s3,s3,-802 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025aa:	00006a97          	auipc	s5,0x6
    800025ae:	cdea8a93          	addi	s5,s5,-802 # 80008288 <digits+0x248>
    printf("\n");
    800025b2:	00006a17          	auipc	s4,0x6
    800025b6:	b16a0a13          	addi	s4,s4,-1258 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	00006b97          	auipc	s7,0x6
    800025be:	d0eb8b93          	addi	s7,s7,-754 # 800082c8 <states.1732>
    800025c2:	a00d                	j	800025e4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c4:	ed86a583          	lw	a1,-296(a3)
    800025c8:	8556                	mv	a0,s5
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fc4080e7          	jalr	-60(ra) # 8000058e <printf>
    printf("\n");
    800025d2:	8552                	mv	a0,s4
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	fba080e7          	jalr	-70(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025dc:	17048493          	addi	s1,s1,368
    800025e0:	03248163          	beq	s1,s2,80002602 <procdump+0x98>
    if(p->state == UNUSED)
    800025e4:	86a6                	mv	a3,s1
    800025e6:	ec04a783          	lw	a5,-320(s1)
    800025ea:	dbed                	beqz	a5,800025dc <procdump+0x72>
      state = "???";
    800025ec:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	fcfb6be3          	bltu	s6,a5,800025c4 <procdump+0x5a>
    800025f2:	1782                	slli	a5,a5,0x20
    800025f4:	9381                	srli	a5,a5,0x20
    800025f6:	078e                	slli	a5,a5,0x3
    800025f8:	97de                	add	a5,a5,s7
    800025fa:	6390                	ld	a2,0(a5)
    800025fc:	f661                	bnez	a2,800025c4 <procdump+0x5a>
      state = "???";
    800025fe:	864e                	mv	a2,s3
    80002600:	b7d1                	j	800025c4 <procdump+0x5a>
  }
}
    80002602:	60a6                	ld	ra,72(sp)
    80002604:	6406                	ld	s0,64(sp)
    80002606:	74e2                	ld	s1,56(sp)
    80002608:	7942                	ld	s2,48(sp)
    8000260a:	79a2                	ld	s3,40(sp)
    8000260c:	7a02                	ld	s4,32(sp)
    8000260e:	6ae2                	ld	s5,24(sp)
    80002610:	6b42                	ld	s6,16(sp)
    80002612:	6ba2                	ld	s7,8(sp)
    80002614:	6161                	addi	sp,sp,80
    80002616:	8082                	ret

0000000080002618 <get_sysinfo>:

// Lab 1
int get_sysinfo(int param)
{
  struct proc *p;
  if(param == 0)
    80002618:	c11d                	beqz	a0,8000263e <get_sysinfo+0x26>
      }
    }
    return process_count;
    
  }
  else if(param == 1)
    8000261a:	4785                	li	a5,1
    8000261c:	04f50663          	beq	a0,a5,80002668 <get_sysinfo+0x50>
      }
    }

    return total_syscalls;
  }
  else if(param == 2)
    80002620:	4789                	li	a5,2
    80002622:	06f51863          	bne	a0,a5,80002692 <get_sysinfo+0x7a>
{
    80002626:	1141                	addi	sp,sp,-16
    80002628:	e406                	sd	ra,8(sp)
    8000262a:	e022                	sd	s0,0(sp)
    8000262c:	0800                	addi	s0,sp,16
  {
    return get_freeMemoryPageCount();
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	52c080e7          	jalr	1324(ra) # 80000b5a <get_freeMemoryPageCount>
  }
  else
  {
    return -1;
  }
}
    80002636:	60a2                	ld	ra,8(sp)
    80002638:	6402                	ld	s0,0(sp)
    8000263a:	0141                	addi	sp,sp,16
    8000263c:	8082                	ret
    for(p = proc; p < &proc[NPROC]; p++){
    8000263e:	0000f797          	auipc	a5,0xf
    80002642:	95278793          	addi	a5,a5,-1710 # 80010f90 <proc>
      if(p->state == RUNNABLE || p->state == RUNNING || p->state == ZOMBIE || p->state == SLEEPING){
    80002646:	460d                	li	a2,3
    for(p = proc; p < &proc[NPROC]; p++){
    80002648:	00014697          	auipc	a3,0x14
    8000264c:	54868693          	addi	a3,a3,1352 # 80016b90 <tickslock>
    80002650:	a029                	j	8000265a <get_sysinfo+0x42>
    80002652:	17078793          	addi	a5,a5,368
    80002656:	00d78863          	beq	a5,a3,80002666 <get_sysinfo+0x4e>
      if(p->state == RUNNABLE || p->state == RUNNING || p->state == ZOMBIE || p->state == SLEEPING){
    8000265a:	4f98                	lw	a4,24(a5)
    8000265c:	3779                	addiw	a4,a4,-2
    8000265e:	fee66ae3          	bltu	a2,a4,80002652 <get_sysinfo+0x3a>
        process_count++;
    80002662:	2505                	addiw	a0,a0,1
    80002664:	b7fd                	j	80002652 <get_sysinfo+0x3a>
    80002666:	8082                	ret
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002668:	0000f797          	auipc	a5,0xf
    8000266c:	92878793          	addi	a5,a5,-1752 # 80010f90 <proc>
    int total_syscalls = 0;
    80002670:	4501                	li	a0,0
    for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    80002672:	00014697          	auipc	a3,0x14
    80002676:	51e68693          	addi	a3,a3,1310 # 80016b90 <tickslock>
    8000267a:	a029                	j	80002684 <get_sysinfo+0x6c>
    8000267c:	17078793          	addi	a5,a5,368
    80002680:	00d78863          	beq	a5,a3,80002690 <get_sysinfo+0x78>
      if(p->state != UNUSED) {
    80002684:	4f98                	lw	a4,24(a5)
    80002686:	db7d                	beqz	a4,8000267c <get_sysinfo+0x64>
        total_syscalls += p->syscall_count;
    80002688:	1687a703          	lw	a4,360(a5)
    8000268c:	9d39                	addw	a0,a0,a4
    8000268e:	b7fd                	j	8000267c <get_sysinfo+0x64>
    80002690:	8082                	ret
    return -1;
    80002692:	557d                	li	a0,-1
}
    80002694:	8082                	ret

0000000080002696 <get_procinfo>:


int get_procinfo(struct pinfo *pi)
{
    80002696:	7179                	addi	sp,sp,-48
    80002698:	f406                	sd	ra,40(sp)
    8000269a:	f022                	sd	s0,32(sp)
    8000269c:	ec26                	sd	s1,24(sp)
    8000269e:	1800                	addi	s0,sp,48
    800026a0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	36c080e7          	jalr	876(ra) # 80001a0e <myproc>
  struct pinfo temp;
  temp.ppid = p->parent->pid;
    800026aa:	7d1c                	ld	a5,56(a0)
    800026ac:	5b9c                	lw	a5,48(a5)
    800026ae:	fcf42823          	sw	a5,-48(s0)
  temp.syscall_count = p->syscall_count;
    800026b2:	16852783          	lw	a5,360(a0)
    800026b6:	fcf42a23          	sw	a5,-44(s0)


  temp.page_usage = (p->sz + PGSIZE - 1) / PGSIZE; 
    800026ba:	653c                	ld	a5,72(a0)
    800026bc:	6705                	lui	a4,0x1
    800026be:	177d                	addi	a4,a4,-1
    800026c0:	97ba                	add	a5,a5,a4
    800026c2:	83b1                	srli	a5,a5,0xc
    800026c4:	fcf42c23          	sw	a5,-40(s0)

  return copyout(p->pagetable, (uint64)pi, (char *)&temp, sizeof(temp));
    800026c8:	46b1                	li	a3,12
    800026ca:	fd040613          	addi	a2,s0,-48
    800026ce:	85a6                	mv	a1,s1
    800026d0:	6928                	ld	a0,80(a0)
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	ffa080e7          	jalr	-6(ra) # 800016cc <copyout>
    // return -1;

  // return 0;


    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6145                	addi	sp,sp,48
    800026e2:	8082                	ret

00000000800026e4 <swtch>:
    800026e4:	00153023          	sd	ra,0(a0)
    800026e8:	00253423          	sd	sp,8(a0)
    800026ec:	e900                	sd	s0,16(a0)
    800026ee:	ed04                	sd	s1,24(a0)
    800026f0:	03253023          	sd	s2,32(a0)
    800026f4:	03353423          	sd	s3,40(a0)
    800026f8:	03453823          	sd	s4,48(a0)
    800026fc:	03553c23          	sd	s5,56(a0)
    80002700:	05653023          	sd	s6,64(a0)
    80002704:	05753423          	sd	s7,72(a0)
    80002708:	05853823          	sd	s8,80(a0)
    8000270c:	05953c23          	sd	s9,88(a0)
    80002710:	07a53023          	sd	s10,96(a0)
    80002714:	07b53423          	sd	s11,104(a0)
    80002718:	0005b083          	ld	ra,0(a1)
    8000271c:	0085b103          	ld	sp,8(a1)
    80002720:	6980                	ld	s0,16(a1)
    80002722:	6d84                	ld	s1,24(a1)
    80002724:	0205b903          	ld	s2,32(a1)
    80002728:	0285b983          	ld	s3,40(a1)
    8000272c:	0305ba03          	ld	s4,48(a1)
    80002730:	0385ba83          	ld	s5,56(a1)
    80002734:	0405bb03          	ld	s6,64(a1)
    80002738:	0485bb83          	ld	s7,72(a1)
    8000273c:	0505bc03          	ld	s8,80(a1)
    80002740:	0585bc83          	ld	s9,88(a1)
    80002744:	0605bd03          	ld	s10,96(a1)
    80002748:	0685bd83          	ld	s11,104(a1)
    8000274c:	8082                	ret

000000008000274e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000274e:	1141                	addi	sp,sp,-16
    80002750:	e406                	sd	ra,8(sp)
    80002752:	e022                	sd	s0,0(sp)
    80002754:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002756:	00006597          	auipc	a1,0x6
    8000275a:	ba258593          	addi	a1,a1,-1118 # 800082f8 <states.1732+0x30>
    8000275e:	00014517          	auipc	a0,0x14
    80002762:	43250513          	addi	a0,a0,1074 # 80016b90 <tickslock>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	43c080e7          	jalr	1084(ra) # 80000ba2 <initlock>
}
    8000276e:	60a2                	ld	ra,8(sp)
    80002770:	6402                	ld	s0,0(sp)
    80002772:	0141                	addi	sp,sp,16
    80002774:	8082                	ret

0000000080002776 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002776:	1141                	addi	sp,sp,-16
    80002778:	e422                	sd	s0,8(sp)
    8000277a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277c:	00003797          	auipc	a5,0x3
    80002780:	52478793          	addi	a5,a5,1316 # 80005ca0 <kernelvec>
    80002784:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002788:	6422                	ld	s0,8(sp)
    8000278a:	0141                	addi	sp,sp,16
    8000278c:	8082                	ret

000000008000278e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000278e:	1141                	addi	sp,sp,-16
    80002790:	e406                	sd	ra,8(sp)
    80002792:	e022                	sd	s0,0(sp)
    80002794:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	278080e7          	jalr	632(ra) # 80001a0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027a8:	00005617          	auipc	a2,0x5
    800027ac:	85860613          	addi	a2,a2,-1960 # 80007000 <_trampoline>
    800027b0:	00005697          	auipc	a3,0x5
    800027b4:	85068693          	addi	a3,a3,-1968 # 80007000 <_trampoline>
    800027b8:	8e91                	sub	a3,a3,a2
    800027ba:	040007b7          	lui	a5,0x4000
    800027be:	17fd                	addi	a5,a5,-1
    800027c0:	07b2                	slli	a5,a5,0xc
    800027c2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ca:	180026f3          	csrr	a3,satp
    800027ce:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027d0:	6d38                	ld	a4,88(a0)
    800027d2:	6134                	ld	a3,64(a0)
    800027d4:	6585                	lui	a1,0x1
    800027d6:	96ae                	add	a3,a3,a1
    800027d8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027da:	6d38                	ld	a4,88(a0)
    800027dc:	00000697          	auipc	a3,0x0
    800027e0:	13068693          	addi	a3,a3,304 # 8000290c <usertrap>
    800027e4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027e6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e8:	8692                	mv	a3,tp
    800027ea:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027f0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027f4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027fc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027fe:	6f18                	ld	a4,24(a4)
    80002800:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002804:	6928                	ld	a0,80(a0)
    80002806:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002808:	00005717          	auipc	a4,0x5
    8000280c:	89470713          	addi	a4,a4,-1900 # 8000709c <userret>
    80002810:	8f11                	sub	a4,a4,a2
    80002812:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002814:	577d                	li	a4,-1
    80002816:	177e                	slli	a4,a4,0x3f
    80002818:	8d59                	or	a0,a0,a4
    8000281a:	9782                	jalr	a5
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002824:	1101                	addi	sp,sp,-32
    80002826:	ec06                	sd	ra,24(sp)
    80002828:	e822                	sd	s0,16(sp)
    8000282a:	e426                	sd	s1,8(sp)
    8000282c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000282e:	00014497          	auipc	s1,0x14
    80002832:	36248493          	addi	s1,s1,866 # 80016b90 <tickslock>
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	3fa080e7          	jalr	1018(ra) # 80000c32 <acquire>
  ticks++;
    80002840:	00006517          	auipc	a0,0x6
    80002844:	0b050513          	addi	a0,a0,176 # 800088f0 <ticks>
    80002848:	411c                	lw	a5,0(a0)
    8000284a:	2785                	addiw	a5,a5,1
    8000284c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	8cc080e7          	jalr	-1844(ra) # 8000211a <wakeup>
  release(&tickslock);
    80002856:	8526                	mv	a0,s1
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	48e080e7          	jalr	1166(ra) # 80000ce6 <release>
}
    80002860:	60e2                	ld	ra,24(sp)
    80002862:	6442                	ld	s0,16(sp)
    80002864:	64a2                	ld	s1,8(sp)
    80002866:	6105                	addi	sp,sp,32
    80002868:	8082                	ret

000000008000286a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000286a:	1101                	addi	sp,sp,-32
    8000286c:	ec06                	sd	ra,24(sp)
    8000286e:	e822                	sd	s0,16(sp)
    80002870:	e426                	sd	s1,8(sp)
    80002872:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002874:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002878:	00074d63          	bltz	a4,80002892 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000287c:	57fd                	li	a5,-1
    8000287e:	17fe                	slli	a5,a5,0x3f
    80002880:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002882:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002884:	06f70363          	beq	a4,a5,800028ea <devintr+0x80>
  }
}
    80002888:	60e2                	ld	ra,24(sp)
    8000288a:	6442                	ld	s0,16(sp)
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	6105                	addi	sp,sp,32
    80002890:	8082                	ret
     (scause & 0xff) == 9){
    80002892:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002896:	46a5                	li	a3,9
    80002898:	fed792e3          	bne	a5,a3,8000287c <devintr+0x12>
    int irq = plic_claim();
    8000289c:	00003097          	auipc	ra,0x3
    800028a0:	50c080e7          	jalr	1292(ra) # 80005da8 <plic_claim>
    800028a4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028a6:	47a9                	li	a5,10
    800028a8:	02f50763          	beq	a0,a5,800028d6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ac:	4785                	li	a5,1
    800028ae:	02f50963          	beq	a0,a5,800028e0 <devintr+0x76>
    return 1;
    800028b2:	4505                	li	a0,1
    } else if(irq){
    800028b4:	d8f1                	beqz	s1,80002888 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028b6:	85a6                	mv	a1,s1
    800028b8:	00006517          	auipc	a0,0x6
    800028bc:	a4850513          	addi	a0,a0,-1464 # 80008300 <states.1732+0x38>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cce080e7          	jalr	-818(ra) # 8000058e <printf>
      plic_complete(irq);
    800028c8:	8526                	mv	a0,s1
    800028ca:	00003097          	auipc	ra,0x3
    800028ce:	502080e7          	jalr	1282(ra) # 80005dcc <plic_complete>
    return 1;
    800028d2:	4505                	li	a0,1
    800028d4:	bf55                	j	80002888 <devintr+0x1e>
      uartintr();
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	0d8080e7          	jalr	216(ra) # 800009ae <uartintr>
    800028de:	b7ed                	j	800028c8 <devintr+0x5e>
      virtio_disk_intr();
    800028e0:	00004097          	auipc	ra,0x4
    800028e4:	a16080e7          	jalr	-1514(ra) # 800062f6 <virtio_disk_intr>
    800028e8:	b7c5                	j	800028c8 <devintr+0x5e>
    if(cpuid() == 0){
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	0f8080e7          	jalr	248(ra) # 800019e2 <cpuid>
    800028f2:	c901                	beqz	a0,80002902 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028f4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028fa:	14479073          	csrw	sip,a5
    return 2;
    800028fe:	4509                	li	a0,2
    80002900:	b761                	j	80002888 <devintr+0x1e>
      clockintr();
    80002902:	00000097          	auipc	ra,0x0
    80002906:	f22080e7          	jalr	-222(ra) # 80002824 <clockintr>
    8000290a:	b7ed                	j	800028f4 <devintr+0x8a>

000000008000290c <usertrap>:
{
    8000290c:	1101                	addi	sp,sp,-32
    8000290e:	ec06                	sd	ra,24(sp)
    80002910:	e822                	sd	s0,16(sp)
    80002912:	e426                	sd	s1,8(sp)
    80002914:	e04a                	sd	s2,0(sp)
    80002916:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002918:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000291c:	1007f793          	andi	a5,a5,256
    80002920:	e3b1                	bnez	a5,80002964 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002922:	00003797          	auipc	a5,0x3
    80002926:	37e78793          	addi	a5,a5,894 # 80005ca0 <kernelvec>
    8000292a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000292e:	fffff097          	auipc	ra,0xfffff
    80002932:	0e0080e7          	jalr	224(ra) # 80001a0e <myproc>
    80002936:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002938:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293a:	14102773          	csrr	a4,sepc
    8000293e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002940:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002944:	47a1                	li	a5,8
    80002946:	02f70763          	beq	a4,a5,80002974 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	f20080e7          	jalr	-224(ra) # 8000286a <devintr>
    80002952:	892a                	mv	s2,a0
    80002954:	c151                	beqz	a0,800029d8 <usertrap+0xcc>
  if(killed(p))
    80002956:	8526                	mv	a0,s1
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	a06080e7          	jalr	-1530(ra) # 8000235e <killed>
    80002960:	c929                	beqz	a0,800029b2 <usertrap+0xa6>
    80002962:	a099                	j	800029a8 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002964:	00006517          	auipc	a0,0x6
    80002968:	9bc50513          	addi	a0,a0,-1604 # 80008320 <states.1732+0x58>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	bd8080e7          	jalr	-1064(ra) # 80000544 <panic>
    if(killed(p))
    80002974:	00000097          	auipc	ra,0x0
    80002978:	9ea080e7          	jalr	-1558(ra) # 8000235e <killed>
    8000297c:	e921                	bnez	a0,800029cc <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000297e:	6cb8                	ld	a4,88(s1)
    80002980:	6f1c                	ld	a5,24(a4)
    80002982:	0791                	addi	a5,a5,4
    80002984:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002986:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000298a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000298e:	10079073          	csrw	sstatus,a5
    syscall();
    80002992:	00000097          	auipc	ra,0x0
    80002996:	2d4080e7          	jalr	724(ra) # 80002c66 <syscall>
  if(killed(p))
    8000299a:	8526                	mv	a0,s1
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	9c2080e7          	jalr	-1598(ra) # 8000235e <killed>
    800029a4:	c911                	beqz	a0,800029b8 <usertrap+0xac>
    800029a6:	4901                	li	s2,0
    exit(-1);
    800029a8:	557d                	li	a0,-1
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	840080e7          	jalr	-1984(ra) # 800021ea <exit>
  if(which_dev == 2)
    800029b2:	4789                	li	a5,2
    800029b4:	04f90f63          	beq	s2,a5,80002a12 <usertrap+0x106>
  usertrapret();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	dd6080e7          	jalr	-554(ra) # 8000278e <usertrapret>
}
    800029c0:	60e2                	ld	ra,24(sp)
    800029c2:	6442                	ld	s0,16(sp)
    800029c4:	64a2                	ld	s1,8(sp)
    800029c6:	6902                	ld	s2,0(sp)
    800029c8:	6105                	addi	sp,sp,32
    800029ca:	8082                	ret
      exit(-1);
    800029cc:	557d                	li	a0,-1
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	81c080e7          	jalr	-2020(ra) # 800021ea <exit>
    800029d6:	b765                	j	8000297e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029dc:	5890                	lw	a2,48(s1)
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	96250513          	addi	a0,a0,-1694 # 80008340 <states.1732+0x78>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	ba8080e7          	jalr	-1112(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	97a50513          	addi	a0,a0,-1670 # 80008370 <states.1732+0xa8>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b90080e7          	jalr	-1136(ra) # 8000058e <printf>
    setkilled(p);
    80002a06:	8526                	mv	a0,s1
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	92a080e7          	jalr	-1750(ra) # 80002332 <setkilled>
    80002a10:	b769                	j	8000299a <usertrap+0x8e>
    yield();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	668080e7          	jalr	1640(ra) # 8000207a <yield>
    80002a1a:	bf79                	j	800029b8 <usertrap+0xac>

0000000080002a1c <kerneltrap>:
{
    80002a1c:	7179                	addi	sp,sp,-48
    80002a1e:	f406                	sd	ra,40(sp)
    80002a20:	f022                	sd	s0,32(sp)
    80002a22:	ec26                	sd	s1,24(sp)
    80002a24:	e84a                	sd	s2,16(sp)
    80002a26:	e44e                	sd	s3,8(sp)
    80002a28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a36:	1004f793          	andi	a5,s1,256
    80002a3a:	cb85                	beqz	a5,80002a6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a42:	ef85                	bnez	a5,80002a7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	e26080e7          	jalr	-474(ra) # 8000286a <devintr>
    80002a4c:	cd1d                	beqz	a0,80002a8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a4e:	4789                	li	a5,2
    80002a50:	06f50a63          	beq	a0,a5,80002ac4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a58:	10049073          	csrw	sstatus,s1
}
    80002a5c:	70a2                	ld	ra,40(sp)
    80002a5e:	7402                	ld	s0,32(sp)
    80002a60:	64e2                	ld	s1,24(sp)
    80002a62:	6942                	ld	s2,16(sp)
    80002a64:	69a2                	ld	s3,8(sp)
    80002a66:	6145                	addi	sp,sp,48
    80002a68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	92650513          	addi	a0,a0,-1754 # 80008390 <states.1732+0xc8>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	ad2080e7          	jalr	-1326(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	93e50513          	addi	a0,a0,-1730 # 800083b8 <states.1732+0xf0>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ac2080e7          	jalr	-1342(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a8a:	85ce                	mv	a1,s3
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	94c50513          	addi	a0,a0,-1716 # 800083d8 <states.1732+0x110>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	afa080e7          	jalr	-1286(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	94450513          	addi	a0,a0,-1724 # 800083e8 <states.1732+0x120>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	ae2080e7          	jalr	-1310(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	94c50513          	addi	a0,a0,-1716 # 80008400 <states.1732+0x138>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	a88080e7          	jalr	-1400(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	f4a080e7          	jalr	-182(ra) # 80001a0e <myproc>
    80002acc:	d541                	beqz	a0,80002a54 <kerneltrap+0x38>
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	f40080e7          	jalr	-192(ra) # 80001a0e <myproc>
    80002ad6:	4d18                	lw	a4,24(a0)
    80002ad8:	4791                	li	a5,4
    80002ada:	f6f71de3          	bne	a4,a5,80002a54 <kerneltrap+0x38>
    yield();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	59c080e7          	jalr	1436(ra) # 8000207a <yield>
    80002ae6:	b7bd                	j	80002a54 <kerneltrap+0x38>

0000000080002ae8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	f1a080e7          	jalr	-230(ra) # 80001a0e <myproc>
  switch (n) {
    80002afc:	4795                	li	a5,5
    80002afe:	0497e163          	bltu	a5,s1,80002b40 <argraw+0x58>
    80002b02:	048a                	slli	s1,s1,0x2
    80002b04:	00006717          	auipc	a4,0x6
    80002b08:	93470713          	addi	a4,a4,-1740 # 80008438 <states.1732+0x170>
    80002b0c:	94ba                	add	s1,s1,a4
    80002b0e:	409c                	lw	a5,0(s1)
    80002b10:	97ba                	add	a5,a5,a4
    80002b12:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b14:	6d3c                	ld	a5,88(a0)
    80002b16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b18:	60e2                	ld	ra,24(sp)
    80002b1a:	6442                	ld	s0,16(sp)
    80002b1c:	64a2                	ld	s1,8(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret
    return p->trapframe->a1;
    80002b22:	6d3c                	ld	a5,88(a0)
    80002b24:	7fa8                	ld	a0,120(a5)
    80002b26:	bfcd                	j	80002b18 <argraw+0x30>
    return p->trapframe->a2;
    80002b28:	6d3c                	ld	a5,88(a0)
    80002b2a:	63c8                	ld	a0,128(a5)
    80002b2c:	b7f5                	j	80002b18 <argraw+0x30>
    return p->trapframe->a3;
    80002b2e:	6d3c                	ld	a5,88(a0)
    80002b30:	67c8                	ld	a0,136(a5)
    80002b32:	b7dd                	j	80002b18 <argraw+0x30>
    return p->trapframe->a4;
    80002b34:	6d3c                	ld	a5,88(a0)
    80002b36:	6bc8                	ld	a0,144(a5)
    80002b38:	b7c5                	j	80002b18 <argraw+0x30>
    return p->trapframe->a5;
    80002b3a:	6d3c                	ld	a5,88(a0)
    80002b3c:	6fc8                	ld	a0,152(a5)
    80002b3e:	bfe9                	j	80002b18 <argraw+0x30>
  panic("argraw");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	8d050513          	addi	a0,a0,-1840 # 80008410 <states.1732+0x148>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	9fc080e7          	jalr	-1540(ra) # 80000544 <panic>

0000000080002b50 <fetchaddr>:
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	addi	s0,sp,32
    80002b5c:	84aa                	mv	s1,a0
    80002b5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	eae080e7          	jalr	-338(ra) # 80001a0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b68:	653c                	ld	a5,72(a0)
    80002b6a:	02f4f863          	bgeu	s1,a5,80002b9a <fetchaddr+0x4a>
    80002b6e:	00848713          	addi	a4,s1,8
    80002b72:	02e7e663          	bltu	a5,a4,80002b9e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b76:	46a1                	li	a3,8
    80002b78:	8626                	mv	a2,s1
    80002b7a:	85ca                	mv	a1,s2
    80002b7c:	6928                	ld	a0,80(a0)
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	bda080e7          	jalr	-1062(ra) # 80001758 <copyin>
    80002b86:	00a03533          	snez	a0,a0
    80002b8a:	40a00533          	neg	a0,a0
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6902                	ld	s2,0(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret
    return -1;
    80002b9a:	557d                	li	a0,-1
    80002b9c:	bfcd                	j	80002b8e <fetchaddr+0x3e>
    80002b9e:	557d                	li	a0,-1
    80002ba0:	b7fd                	j	80002b8e <fetchaddr+0x3e>

0000000080002ba2 <fetchstr>:
{
    80002ba2:	7179                	addi	sp,sp,-48
    80002ba4:	f406                	sd	ra,40(sp)
    80002ba6:	f022                	sd	s0,32(sp)
    80002ba8:	ec26                	sd	s1,24(sp)
    80002baa:	e84a                	sd	s2,16(sp)
    80002bac:	e44e                	sd	s3,8(sp)
    80002bae:	1800                	addi	s0,sp,48
    80002bb0:	892a                	mv	s2,a0
    80002bb2:	84ae                	mv	s1,a1
    80002bb4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	e58080e7          	jalr	-424(ra) # 80001a0e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bbe:	86ce                	mv	a3,s3
    80002bc0:	864a                	mv	a2,s2
    80002bc2:	85a6                	mv	a1,s1
    80002bc4:	6928                	ld	a0,80(a0)
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	c1e080e7          	jalr	-994(ra) # 800017e4 <copyinstr>
    80002bce:	00054e63          	bltz	a0,80002bea <fetchstr+0x48>
  return strlen(buf);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	2de080e7          	jalr	734(ra) # 80000eb2 <strlen>
}
    80002bdc:	70a2                	ld	ra,40(sp)
    80002bde:	7402                	ld	s0,32(sp)
    80002be0:	64e2                	ld	s1,24(sp)
    80002be2:	6942                	ld	s2,16(sp)
    80002be4:	69a2                	ld	s3,8(sp)
    80002be6:	6145                	addi	sp,sp,48
    80002be8:	8082                	ret
    return -1;
    80002bea:	557d                	li	a0,-1
    80002bec:	bfc5                	j	80002bdc <fetchstr+0x3a>

0000000080002bee <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bee:	1101                	addi	sp,sp,-32
    80002bf0:	ec06                	sd	ra,24(sp)
    80002bf2:	e822                	sd	s0,16(sp)
    80002bf4:	e426                	sd	s1,8(sp)
    80002bf6:	1000                	addi	s0,sp,32
    80002bf8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	eee080e7          	jalr	-274(ra) # 80002ae8 <argraw>
    80002c02:	c088                	sw	a0,0(s1)
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret

0000000080002c0e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c0e:	1101                	addi	sp,sp,-32
    80002c10:	ec06                	sd	ra,24(sp)
    80002c12:	e822                	sd	s0,16(sp)
    80002c14:	e426                	sd	s1,8(sp)
    80002c16:	1000                	addi	s0,sp,32
    80002c18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	ece080e7          	jalr	-306(ra) # 80002ae8 <argraw>
    80002c22:	e088                	sd	a0,0(s1)
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	e84a                	sd	s2,16(sp)
    80002c38:	1800                	addi	s0,sp,48
    80002c3a:	84ae                	mv	s1,a1
    80002c3c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c3e:	fd840593          	addi	a1,s0,-40
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	fcc080e7          	jalr	-52(ra) # 80002c0e <argaddr>
  return fetchstr(addr, buf, max);
    80002c4a:	864a                	mv	a2,s2
    80002c4c:	85a6                	mv	a1,s1
    80002c4e:	fd843503          	ld	a0,-40(s0)
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	f50080e7          	jalr	-176(ra) # 80002ba2 <fetchstr>
}
    80002c5a:	70a2                	ld	ra,40(sp)
    80002c5c:	7402                	ld	s0,32(sp)
    80002c5e:	64e2                	ld	s1,24(sp)
    80002c60:	6942                	ld	s2,16(sp)
    80002c62:	6145                	addi	sp,sp,48
    80002c64:	8082                	ret

0000000080002c66 <syscall>:
[SYS_procinfo] sys_procinfo,
};

void
syscall(void)
{
    80002c66:	7179                	addi	sp,sp,-48
    80002c68:	f406                	sd	ra,40(sp)
    80002c6a:	f022                	sd	s0,32(sp)
    80002c6c:	ec26                	sd	s1,24(sp)
    80002c6e:	e84a                	sd	s2,16(sp)
    80002c70:	e44e                	sd	s3,8(sp)
    80002c72:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d9a080e7          	jalr	-614(ra) # 80001a0e <myproc>
    80002c7c:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002c7e:	05853983          	ld	s3,88(a0)
    80002c82:	0a89b783          	ld	a5,168(s3)
    80002c86:	0007891b          	sext.w	s2,a5
  
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c8a:	37fd                	addiw	a5,a5,-1
    80002c8c:	4759                	li	a4,22
    80002c8e:	02f76d63          	bltu	a4,a5,80002cc8 <syscall+0x62>
    80002c92:	00391713          	slli	a4,s2,0x3
    80002c96:	00005797          	auipc	a5,0x5
    80002c9a:	7ba78793          	addi	a5,a5,1978 # 80008450 <syscalls>
    80002c9e:	97ba                	add	a5,a5,a4
    80002ca0:	639c                	ld	a5,0(a5)
    80002ca2:	c39d                	beqz	a5,80002cc8 <syscall+0x62>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    int cs_calls = num;
    p->trapframe->a0 = syscalls[num]();
    80002ca4:	9782                	jalr	a5
    80002ca6:	06a9b823          	sd	a0,112(s3)

    // Lab 1
    if(!(cs_calls == SYS_sysinfo && p->trapframe->a0 == 1))
    80002caa:	47d9                	li	a5,22
    80002cac:	00f90863          	beq	s2,a5,80002cbc <syscall+0x56>
    {
      p->syscall_count++;
    80002cb0:	1684a783          	lw	a5,360(s1)
    80002cb4:	2785                	addiw	a5,a5,1
    80002cb6:	16f4a423          	sw	a5,360(s1)
    80002cba:	a035                	j	80002ce6 <syscall+0x80>
    if(!(cs_calls == SYS_sysinfo && p->trapframe->a0 == 1))
    80002cbc:	6cbc                	ld	a5,88(s1)
    80002cbe:	7bb8                	ld	a4,112(a5)
    80002cc0:	4785                	li	a5,1
    80002cc2:	fef717e3          	bne	a4,a5,80002cb0 <syscall+0x4a>
    80002cc6:	a005                	j	80002ce6 <syscall+0x80>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cc8:	86ca                	mv	a3,s2
    80002cca:	15848613          	addi	a2,s1,344
    80002cce:	588c                	lw	a1,48(s1)
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	74850513          	addi	a0,a0,1864 # 80008418 <states.1732+0x150>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	8b6080e7          	jalr	-1866(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce0:	6cbc                	ld	a5,88(s1)
    80002ce2:	577d                	li	a4,-1
    80002ce4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ce6:	70a2                	ld	ra,40(sp)
    80002ce8:	7402                	ld	s0,32(sp)
    80002cea:	64e2                	ld	s1,24(sp)
    80002cec:	6942                	ld	s2,16(sp)
    80002cee:	69a2                	ld	s3,8(sp)
    80002cf0:	6145                	addi	sp,sp,48
    80002cf2:	8082                	ret

0000000080002cf4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cf4:	1101                	addi	sp,sp,-32
    80002cf6:	ec06                	sd	ra,24(sp)
    80002cf8:	e822                	sd	s0,16(sp)
    80002cfa:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cfc:	fec40593          	addi	a1,s0,-20
    80002d00:	4501                	li	a0,0
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	eec080e7          	jalr	-276(ra) # 80002bee <argint>
  exit(n);
    80002d0a:	fec42503          	lw	a0,-20(s0)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	4dc080e7          	jalr	1244(ra) # 800021ea <exit>
  return 0;  // not reached
}
    80002d16:	4501                	li	a0,0
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	6105                	addi	sp,sp,32
    80002d1e:	8082                	ret

0000000080002d20 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d20:	1141                	addi	sp,sp,-16
    80002d22:	e406                	sd	ra,8(sp)
    80002d24:	e022                	sd	s0,0(sp)
    80002d26:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	ce6080e7          	jalr	-794(ra) # 80001a0e <myproc>
}
    80002d30:	5908                	lw	a0,48(a0)
    80002d32:	60a2                	ld	ra,8(sp)
    80002d34:	6402                	ld	s0,0(sp)
    80002d36:	0141                	addi	sp,sp,16
    80002d38:	8082                	ret

0000000080002d3a <sys_fork>:

uint64
sys_fork(void)
{
    80002d3a:	1141                	addi	sp,sp,-16
    80002d3c:	e406                	sd	ra,8(sp)
    80002d3e:	e022                	sd	s0,0(sp)
    80002d40:	0800                	addi	s0,sp,16
  return fork();
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	086080e7          	jalr	134(ra) # 80001dc8 <fork>
}
    80002d4a:	60a2                	ld	ra,8(sp)
    80002d4c:	6402                	ld	s0,0(sp)
    80002d4e:	0141                	addi	sp,sp,16
    80002d50:	8082                	ret

0000000080002d52 <sys_wait>:

uint64
sys_wait(void)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d5a:	fe840593          	addi	a1,s0,-24
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	eae080e7          	jalr	-338(ra) # 80002c0e <argaddr>
  return wait(p);
    80002d68:	fe843503          	ld	a0,-24(s0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	624080e7          	jalr	1572(ra) # 80002390 <wait>
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d7c:	7179                	addi	sp,sp,-48
    80002d7e:	f406                	sd	ra,40(sp)
    80002d80:	f022                	sd	s0,32(sp)
    80002d82:	ec26                	sd	s1,24(sp)
    80002d84:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d86:	fdc40593          	addi	a1,s0,-36
    80002d8a:	4501                	li	a0,0
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	e62080e7          	jalr	-414(ra) # 80002bee <argint>
  addr = myproc()->sz;
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	c7a080e7          	jalr	-902(ra) # 80001a0e <myproc>
    80002d9c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d9e:	fdc42503          	lw	a0,-36(s0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	fca080e7          	jalr	-54(ra) # 80001d6c <growproc>
    80002daa:	00054863          	bltz	a0,80002dba <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dae:	8526                	mv	a0,s1
    80002db0:	70a2                	ld	ra,40(sp)
    80002db2:	7402                	ld	s0,32(sp)
    80002db4:	64e2                	ld	s1,24(sp)
    80002db6:	6145                	addi	sp,sp,48
    80002db8:	8082                	ret
    return -1;
    80002dba:	54fd                	li	s1,-1
    80002dbc:	bfcd                	j	80002dae <sys_sbrk+0x32>

0000000080002dbe <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dbe:	7139                	addi	sp,sp,-64
    80002dc0:	fc06                	sd	ra,56(sp)
    80002dc2:	f822                	sd	s0,48(sp)
    80002dc4:	f426                	sd	s1,40(sp)
    80002dc6:	f04a                	sd	s2,32(sp)
    80002dc8:	ec4e                	sd	s3,24(sp)
    80002dca:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dcc:	fcc40593          	addi	a1,s0,-52
    80002dd0:	4501                	li	a0,0
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	e1c080e7          	jalr	-484(ra) # 80002bee <argint>
  acquire(&tickslock);
    80002dda:	00014517          	auipc	a0,0x14
    80002dde:	db650513          	addi	a0,a0,-586 # 80016b90 <tickslock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	e50080e7          	jalr	-432(ra) # 80000c32 <acquire>
  ticks0 = ticks;
    80002dea:	00006917          	auipc	s2,0x6
    80002dee:	b0692903          	lw	s2,-1274(s2) # 800088f0 <ticks>
  while(ticks - ticks0 < n){
    80002df2:	fcc42783          	lw	a5,-52(s0)
    80002df6:	cf9d                	beqz	a5,80002e34 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002df8:	00014997          	auipc	s3,0x14
    80002dfc:	d9898993          	addi	s3,s3,-616 # 80016b90 <tickslock>
    80002e00:	00006497          	auipc	s1,0x6
    80002e04:	af048493          	addi	s1,s1,-1296 # 800088f0 <ticks>
    if(killed(myproc())){
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	c06080e7          	jalr	-1018(ra) # 80001a0e <myproc>
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	54e080e7          	jalr	1358(ra) # 8000235e <killed>
    80002e18:	ed15                	bnez	a0,80002e54 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e1a:	85ce                	mv	a1,s3
    80002e1c:	8526                	mv	a0,s1
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	298080e7          	jalr	664(ra) # 800020b6 <sleep>
  while(ticks - ticks0 < n){
    80002e26:	409c                	lw	a5,0(s1)
    80002e28:	412787bb          	subw	a5,a5,s2
    80002e2c:	fcc42703          	lw	a4,-52(s0)
    80002e30:	fce7ece3          	bltu	a5,a4,80002e08 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	d5c50513          	addi	a0,a0,-676 # 80016b90 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	eaa080e7          	jalr	-342(ra) # 80000ce6 <release>
  return 0;
    80002e44:	4501                	li	a0,0
}
    80002e46:	70e2                	ld	ra,56(sp)
    80002e48:	7442                	ld	s0,48(sp)
    80002e4a:	74a2                	ld	s1,40(sp)
    80002e4c:	7902                	ld	s2,32(sp)
    80002e4e:	69e2                	ld	s3,24(sp)
    80002e50:	6121                	addi	sp,sp,64
    80002e52:	8082                	ret
      release(&tickslock);
    80002e54:	00014517          	auipc	a0,0x14
    80002e58:	d3c50513          	addi	a0,a0,-708 # 80016b90 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	e8a080e7          	jalr	-374(ra) # 80000ce6 <release>
      return -1;
    80002e64:	557d                	li	a0,-1
    80002e66:	b7c5                	j	80002e46 <sys_sleep+0x88>

0000000080002e68 <sys_kill>:

uint64
sys_kill(void)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e70:	fec40593          	addi	a1,s0,-20
    80002e74:	4501                	li	a0,0
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	d78080e7          	jalr	-648(ra) # 80002bee <argint>
  return kill(pid);
    80002e7e:	fec42503          	lw	a0,-20(s0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	43e080e7          	jalr	1086(ra) # 800022c0 <kill>
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	6105                	addi	sp,sp,32
    80002e90:	8082                	ret

0000000080002e92 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e92:	1101                	addi	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	e426                	sd	s1,8(sp)
    80002e9a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e9c:	00014517          	auipc	a0,0x14
    80002ea0:	cf450513          	addi	a0,a0,-780 # 80016b90 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	d8e080e7          	jalr	-626(ra) # 80000c32 <acquire>
  xticks = ticks;
    80002eac:	00006497          	auipc	s1,0x6
    80002eb0:	a444a483          	lw	s1,-1468(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002eb4:	00014517          	auipc	a0,0x14
    80002eb8:	cdc50513          	addi	a0,a0,-804 # 80016b90 <tickslock>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	e2a080e7          	jalr	-470(ra) # 80000ce6 <release>
  return xticks;
}
    80002ec4:	02049513          	slli	a0,s1,0x20
    80002ec8:	9101                	srli	a0,a0,0x20
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6105                	addi	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <sys_sysinfo>:

// Lab 1
uint64
sys_sysinfo(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002edc:	fec40593          	addi	a1,s0,-20
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	d0c080e7          	jalr	-756(ra) # 80002bee <argint>
  return get_sysinfo(n);
    80002eea:	fec42503          	lw	a0,-20(s0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	72a080e7          	jalr	1834(ra) # 80002618 <get_sysinfo>
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_procinfo>:

uint64
sys_procinfo(void)
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	1000                	addi	s0,sp,32
  uint64 addr;
  argaddr(0, &addr);
    80002f06:	fe840593          	addi	a1,s0,-24
    80002f0a:	4501                	li	a0,0
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	d02080e7          	jalr	-766(ra) # 80002c0e <argaddr>
  return get_procinfo((struct pinfo*)addr);
    80002f14:	fe843503          	ld	a0,-24(s0)
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	77e080e7          	jalr	1918(ra) # 80002696 <get_procinfo>
}
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	6105                	addi	sp,sp,32
    80002f26:	8082                	ret

0000000080002f28 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f28:	7179                	addi	sp,sp,-48
    80002f2a:	f406                	sd	ra,40(sp)
    80002f2c:	f022                	sd	s0,32(sp)
    80002f2e:	ec26                	sd	s1,24(sp)
    80002f30:	e84a                	sd	s2,16(sp)
    80002f32:	e44e                	sd	s3,8(sp)
    80002f34:	e052                	sd	s4,0(sp)
    80002f36:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f38:	00005597          	auipc	a1,0x5
    80002f3c:	5d858593          	addi	a1,a1,1496 # 80008510 <syscalls+0xc0>
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	c6850513          	addi	a0,a0,-920 # 80016ba8 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	c5a080e7          	jalr	-934(ra) # 80000ba2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f50:	0001c797          	auipc	a5,0x1c
    80002f54:	c5878793          	addi	a5,a5,-936 # 8001eba8 <bcache+0x8000>
    80002f58:	0001c717          	auipc	a4,0x1c
    80002f5c:	eb870713          	addi	a4,a4,-328 # 8001ee10 <bcache+0x8268>
    80002f60:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f64:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f68:	00014497          	auipc	s1,0x14
    80002f6c:	c5848493          	addi	s1,s1,-936 # 80016bc0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f70:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f72:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f74:	00005a17          	auipc	s4,0x5
    80002f78:	5a4a0a13          	addi	s4,s4,1444 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f7c:	2b893783          	ld	a5,696(s2)
    80002f80:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f82:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f86:	85d2                	mv	a1,s4
    80002f88:	01048513          	addi	a0,s1,16
    80002f8c:	00001097          	auipc	ra,0x1
    80002f90:	4c4080e7          	jalr	1220(ra) # 80004450 <initsleeplock>
    bcache.head.next->prev = b;
    80002f94:	2b893783          	ld	a5,696(s2)
    80002f98:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f9a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9e:	45848493          	addi	s1,s1,1112
    80002fa2:	fd349de3          	bne	s1,s3,80002f7c <binit+0x54>
  }
}
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6942                	ld	s2,16(sp)
    80002fae:	69a2                	ld	s3,8(sp)
    80002fb0:	6a02                	ld	s4,0(sp)
    80002fb2:	6145                	addi	sp,sp,48
    80002fb4:	8082                	ret

0000000080002fb6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb6:	7179                	addi	sp,sp,-48
    80002fb8:	f406                	sd	ra,40(sp)
    80002fba:	f022                	sd	s0,32(sp)
    80002fbc:	ec26                	sd	s1,24(sp)
    80002fbe:	e84a                	sd	s2,16(sp)
    80002fc0:	e44e                	sd	s3,8(sp)
    80002fc2:	1800                	addi	s0,sp,48
    80002fc4:	89aa                	mv	s3,a0
    80002fc6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	be050513          	addi	a0,a0,-1056 # 80016ba8 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	c62080e7          	jalr	-926(ra) # 80000c32 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd8:	0001c497          	auipc	s1,0x1c
    80002fdc:	e884b483          	ld	s1,-376(s1) # 8001ee60 <bcache+0x82b8>
    80002fe0:	0001c797          	auipc	a5,0x1c
    80002fe4:	e3078793          	addi	a5,a5,-464 # 8001ee10 <bcache+0x8268>
    80002fe8:	02f48f63          	beq	s1,a5,80003026 <bread+0x70>
    80002fec:	873e                	mv	a4,a5
    80002fee:	a021                	j	80002ff6 <bread+0x40>
    80002ff0:	68a4                	ld	s1,80(s1)
    80002ff2:	02e48a63          	beq	s1,a4,80003026 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff6:	449c                	lw	a5,8(s1)
    80002ff8:	ff379ce3          	bne	a5,s3,80002ff0 <bread+0x3a>
    80002ffc:	44dc                	lw	a5,12(s1)
    80002ffe:	ff2799e3          	bne	a5,s2,80002ff0 <bread+0x3a>
      b->refcnt++;
    80003002:	40bc                	lw	a5,64(s1)
    80003004:	2785                	addiw	a5,a5,1
    80003006:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	ba050513          	addi	a0,a0,-1120 # 80016ba8 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	cd6080e7          	jalr	-810(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    80003018:	01048513          	addi	a0,s1,16
    8000301c:	00001097          	auipc	ra,0x1
    80003020:	46e080e7          	jalr	1134(ra) # 8000448a <acquiresleep>
      return b;
    80003024:	a8b9                	j	80003082 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003026:	0001c497          	auipc	s1,0x1c
    8000302a:	e324b483          	ld	s1,-462(s1) # 8001ee58 <bcache+0x82b0>
    8000302e:	0001c797          	auipc	a5,0x1c
    80003032:	de278793          	addi	a5,a5,-542 # 8001ee10 <bcache+0x8268>
    80003036:	00f48863          	beq	s1,a5,80003046 <bread+0x90>
    8000303a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000303c:	40bc                	lw	a5,64(s1)
    8000303e:	cf81                	beqz	a5,80003056 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003040:	64a4                	ld	s1,72(s1)
    80003042:	fee49de3          	bne	s1,a4,8000303c <bread+0x86>
  panic("bget: no buffers");
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	4da50513          	addi	a0,a0,1242 # 80008520 <syscalls+0xd0>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	4f6080e7          	jalr	1270(ra) # 80000544 <panic>
      b->dev = dev;
    80003056:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000305a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003062:	4785                	li	a5,1
    80003064:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003066:	00014517          	auipc	a0,0x14
    8000306a:	b4250513          	addi	a0,a0,-1214 # 80016ba8 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	c78080e7          	jalr	-904(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    80003076:	01048513          	addi	a0,s1,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	410080e7          	jalr	1040(ra) # 8000448a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003082:	409c                	lw	a5,0(s1)
    80003084:	cb89                	beqz	a5,80003096 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003086:	8526                	mv	a0,s1
    80003088:	70a2                	ld	ra,40(sp)
    8000308a:	7402                	ld	s0,32(sp)
    8000308c:	64e2                	ld	s1,24(sp)
    8000308e:	6942                	ld	s2,16(sp)
    80003090:	69a2                	ld	s3,8(sp)
    80003092:	6145                	addi	sp,sp,48
    80003094:	8082                	ret
    virtio_disk_rw(b, 0);
    80003096:	4581                	li	a1,0
    80003098:	8526                	mv	a0,s1
    8000309a:	00003097          	auipc	ra,0x3
    8000309e:	fce080e7          	jalr	-50(ra) # 80006068 <virtio_disk_rw>
    b->valid = 1;
    800030a2:	4785                	li	a5,1
    800030a4:	c09c                	sw	a5,0(s1)
  return b;
    800030a6:	b7c5                	j	80003086 <bread+0xd0>

00000000800030a8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	1000                	addi	s0,sp,32
    800030b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b4:	0541                	addi	a0,a0,16
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	46e080e7          	jalr	1134(ra) # 80004524 <holdingsleep>
    800030be:	cd01                	beqz	a0,800030d6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c0:	4585                	li	a1,1
    800030c2:	8526                	mv	a0,s1
    800030c4:	00003097          	auipc	ra,0x3
    800030c8:	fa4080e7          	jalr	-92(ra) # 80006068 <virtio_disk_rw>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    panic("bwrite");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	46250513          	addi	a0,a0,1122 # 80008538 <syscalls+0xe8>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	466080e7          	jalr	1126(ra) # 80000544 <panic>

00000000800030e6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	e04a                	sd	s2,0(sp)
    800030f0:	1000                	addi	s0,sp,32
    800030f2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f4:	01050913          	addi	s2,a0,16
    800030f8:	854a                	mv	a0,s2
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	42a080e7          	jalr	1066(ra) # 80004524 <holdingsleep>
    80003102:	c92d                	beqz	a0,80003174 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003104:	854a                	mv	a0,s2
    80003106:	00001097          	auipc	ra,0x1
    8000310a:	3da080e7          	jalr	986(ra) # 800044e0 <releasesleep>

  acquire(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	a9a50513          	addi	a0,a0,-1382 # 80016ba8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b1c080e7          	jalr	-1252(ra) # 80000c32 <acquire>
  b->refcnt--;
    8000311e:	40bc                	lw	a5,64(s1)
    80003120:	37fd                	addiw	a5,a5,-1
    80003122:	0007871b          	sext.w	a4,a5
    80003126:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003128:	eb05                	bnez	a4,80003158 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000312a:	68bc                	ld	a5,80(s1)
    8000312c:	64b8                	ld	a4,72(s1)
    8000312e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003130:	64bc                	ld	a5,72(s1)
    80003132:	68b8                	ld	a4,80(s1)
    80003134:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003136:	0001c797          	auipc	a5,0x1c
    8000313a:	a7278793          	addi	a5,a5,-1422 # 8001eba8 <bcache+0x8000>
    8000313e:	2b87b703          	ld	a4,696(a5)
    80003142:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003144:	0001c717          	auipc	a4,0x1c
    80003148:	ccc70713          	addi	a4,a4,-820 # 8001ee10 <bcache+0x8268>
    8000314c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314e:	2b87b703          	ld	a4,696(a5)
    80003152:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003154:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003158:	00014517          	auipc	a0,0x14
    8000315c:	a5050513          	addi	a0,a0,-1456 # 80016ba8 <bcache>
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	b86080e7          	jalr	-1146(ra) # 80000ce6 <release>
}
    80003168:	60e2                	ld	ra,24(sp)
    8000316a:	6442                	ld	s0,16(sp)
    8000316c:	64a2                	ld	s1,8(sp)
    8000316e:	6902                	ld	s2,0(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret
    panic("brelse");
    80003174:	00005517          	auipc	a0,0x5
    80003178:	3cc50513          	addi	a0,a0,972 # 80008540 <syscalls+0xf0>
    8000317c:	ffffd097          	auipc	ra,0xffffd
    80003180:	3c8080e7          	jalr	968(ra) # 80000544 <panic>

0000000080003184 <bpin>:

void
bpin(struct buf *b) {
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003190:	00014517          	auipc	a0,0x14
    80003194:	a1850513          	addi	a0,a0,-1512 # 80016ba8 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	a9a080e7          	jalr	-1382(ra) # 80000c32 <acquire>
  b->refcnt++;
    800031a0:	40bc                	lw	a5,64(s1)
    800031a2:	2785                	addiw	a5,a5,1
    800031a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a6:	00014517          	auipc	a0,0x14
    800031aa:	a0250513          	addi	a0,a0,-1534 # 80016ba8 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	b38080e7          	jalr	-1224(ra) # 80000ce6 <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <bunpin>:

void
bunpin(struct buf *b) {
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	9dc50513          	addi	a0,a0,-1572 # 80016ba8 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	a5e080e7          	jalr	-1442(ra) # 80000c32 <acquire>
  b->refcnt--;
    800031dc:	40bc                	lw	a5,64(s1)
    800031de:	37fd                	addiw	a5,a5,-1
    800031e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e2:	00014517          	auipc	a0,0x14
    800031e6:	9c650513          	addi	a0,a0,-1594 # 80016ba8 <bcache>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	afc080e7          	jalr	-1284(ra) # 80000ce6 <release>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret

00000000800031fc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031fc:	1101                	addi	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	e04a                	sd	s2,0(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000320a:	00d5d59b          	srliw	a1,a1,0xd
    8000320e:	0001c797          	auipc	a5,0x1c
    80003212:	0767a783          	lw	a5,118(a5) # 8001f284 <sb+0x1c>
    80003216:	9dbd                	addw	a1,a1,a5
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	d9e080e7          	jalr	-610(ra) # 80002fb6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003220:	0074f713          	andi	a4,s1,7
    80003224:	4785                	li	a5,1
    80003226:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000322a:	14ce                	slli	s1,s1,0x33
    8000322c:	90d9                	srli	s1,s1,0x36
    8000322e:	00950733          	add	a4,a0,s1
    80003232:	05874703          	lbu	a4,88(a4)
    80003236:	00e7f6b3          	and	a3,a5,a4
    8000323a:	c69d                	beqz	a3,80003268 <bfree+0x6c>
    8000323c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323e:	94aa                	add	s1,s1,a0
    80003240:	fff7c793          	not	a5,a5
    80003244:	8ff9                	and	a5,a5,a4
    80003246:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000324a:	00001097          	auipc	ra,0x1
    8000324e:	120080e7          	jalr	288(ra) # 8000436a <log_write>
  brelse(bp);
    80003252:	854a                	mv	a0,s2
    80003254:	00000097          	auipc	ra,0x0
    80003258:	e92080e7          	jalr	-366(ra) # 800030e6 <brelse>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6902                	ld	s2,0(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret
    panic("freeing free block");
    80003268:	00005517          	auipc	a0,0x5
    8000326c:	2e050513          	addi	a0,a0,736 # 80008548 <syscalls+0xf8>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	2d4080e7          	jalr	724(ra) # 80000544 <panic>

0000000080003278 <balloc>:
{
    80003278:	711d                	addi	sp,sp,-96
    8000327a:	ec86                	sd	ra,88(sp)
    8000327c:	e8a2                	sd	s0,80(sp)
    8000327e:	e4a6                	sd	s1,72(sp)
    80003280:	e0ca                	sd	s2,64(sp)
    80003282:	fc4e                	sd	s3,56(sp)
    80003284:	f852                	sd	s4,48(sp)
    80003286:	f456                	sd	s5,40(sp)
    80003288:	f05a                	sd	s6,32(sp)
    8000328a:	ec5e                	sd	s7,24(sp)
    8000328c:	e862                	sd	s8,16(sp)
    8000328e:	e466                	sd	s9,8(sp)
    80003290:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003292:	0001c797          	auipc	a5,0x1c
    80003296:	fda7a783          	lw	a5,-38(a5) # 8001f26c <sb+0x4>
    8000329a:	10078163          	beqz	a5,8000339c <balloc+0x124>
    8000329e:	8baa                	mv	s7,a0
    800032a0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a2:	0001cb17          	auipc	s6,0x1c
    800032a6:	fc6b0b13          	addi	s6,s6,-58 # 8001f268 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032aa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032ac:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ae:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b0:	6c89                	lui	s9,0x2
    800032b2:	a061                	j	8000333a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032b4:	974a                	add	a4,a4,s2
    800032b6:	8fd5                	or	a5,a5,a3
    800032b8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00001097          	auipc	ra,0x1
    800032c2:	0ac080e7          	jalr	172(ra) # 8000436a <log_write>
        brelse(bp);
    800032c6:	854a                	mv	a0,s2
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	e1e080e7          	jalr	-482(ra) # 800030e6 <brelse>
  bp = bread(dev, bno);
    800032d0:	85a6                	mv	a1,s1
    800032d2:	855e                	mv	a0,s7
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	ce2080e7          	jalr	-798(ra) # 80002fb6 <bread>
    800032dc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032de:	40000613          	li	a2,1024
    800032e2:	4581                	li	a1,0
    800032e4:	05850513          	addi	a0,a0,88
    800032e8:	ffffe097          	auipc	ra,0xffffe
    800032ec:	a46080e7          	jalr	-1466(ra) # 80000d2e <memset>
  log_write(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00001097          	auipc	ra,0x1
    800032f6:	078080e7          	jalr	120(ra) # 8000436a <log_write>
  brelse(bp);
    800032fa:	854a                	mv	a0,s2
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	dea080e7          	jalr	-534(ra) # 800030e6 <brelse>
}
    80003304:	8526                	mv	a0,s1
    80003306:	60e6                	ld	ra,88(sp)
    80003308:	6446                	ld	s0,80(sp)
    8000330a:	64a6                	ld	s1,72(sp)
    8000330c:	6906                	ld	s2,64(sp)
    8000330e:	79e2                	ld	s3,56(sp)
    80003310:	7a42                	ld	s4,48(sp)
    80003312:	7aa2                	ld	s5,40(sp)
    80003314:	7b02                	ld	s6,32(sp)
    80003316:	6be2                	ld	s7,24(sp)
    80003318:	6c42                	ld	s8,16(sp)
    8000331a:	6ca2                	ld	s9,8(sp)
    8000331c:	6125                	addi	sp,sp,96
    8000331e:	8082                	ret
    brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	dc4080e7          	jalr	-572(ra) # 800030e6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000332a:	015c87bb          	addw	a5,s9,s5
    8000332e:	00078a9b          	sext.w	s5,a5
    80003332:	004b2703          	lw	a4,4(s6)
    80003336:	06eaf363          	bgeu	s5,a4,8000339c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000333a:	41fad79b          	sraiw	a5,s5,0x1f
    8000333e:	0137d79b          	srliw	a5,a5,0x13
    80003342:	015787bb          	addw	a5,a5,s5
    80003346:	40d7d79b          	sraiw	a5,a5,0xd
    8000334a:	01cb2583          	lw	a1,28(s6)
    8000334e:	9dbd                	addw	a1,a1,a5
    80003350:	855e                	mv	a0,s7
    80003352:	00000097          	auipc	ra,0x0
    80003356:	c64080e7          	jalr	-924(ra) # 80002fb6 <bread>
    8000335a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335c:	004b2503          	lw	a0,4(s6)
    80003360:	000a849b          	sext.w	s1,s5
    80003364:	8662                	mv	a2,s8
    80003366:	faa4fde3          	bgeu	s1,a0,80003320 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000336a:	41f6579b          	sraiw	a5,a2,0x1f
    8000336e:	01d7d69b          	srliw	a3,a5,0x1d
    80003372:	00c6873b          	addw	a4,a3,a2
    80003376:	00777793          	andi	a5,a4,7
    8000337a:	9f95                	subw	a5,a5,a3
    8000337c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003380:	4037571b          	sraiw	a4,a4,0x3
    80003384:	00e906b3          	add	a3,s2,a4
    80003388:	0586c683          	lbu	a3,88(a3)
    8000338c:	00d7f5b3          	and	a1,a5,a3
    80003390:	d195                	beqz	a1,800032b4 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003392:	2605                	addiw	a2,a2,1
    80003394:	2485                	addiw	s1,s1,1
    80003396:	fd4618e3          	bne	a2,s4,80003366 <balloc+0xee>
    8000339a:	b759                	j	80003320 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000339c:	00005517          	auipc	a0,0x5
    800033a0:	1c450513          	addi	a0,a0,452 # 80008560 <syscalls+0x110>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	1ea080e7          	jalr	490(ra) # 8000058e <printf>
  return 0;
    800033ac:	4481                	li	s1,0
    800033ae:	bf99                	j	80003304 <balloc+0x8c>

00000000800033b0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033b0:	7179                	addi	sp,sp,-48
    800033b2:	f406                	sd	ra,40(sp)
    800033b4:	f022                	sd	s0,32(sp)
    800033b6:	ec26                	sd	s1,24(sp)
    800033b8:	e84a                	sd	s2,16(sp)
    800033ba:	e44e                	sd	s3,8(sp)
    800033bc:	e052                	sd	s4,0(sp)
    800033be:	1800                	addi	s0,sp,48
    800033c0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c2:	47ad                	li	a5,11
    800033c4:	02b7e763          	bltu	a5,a1,800033f2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033c8:	02059493          	slli	s1,a1,0x20
    800033cc:	9081                	srli	s1,s1,0x20
    800033ce:	048a                	slli	s1,s1,0x2
    800033d0:	94aa                	add	s1,s1,a0
    800033d2:	0504a903          	lw	s2,80(s1)
    800033d6:	06091e63          	bnez	s2,80003452 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033da:	4108                	lw	a0,0(a0)
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	e9c080e7          	jalr	-356(ra) # 80003278 <balloc>
    800033e4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033e8:	06090563          	beqz	s2,80003452 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033ec:	0524a823          	sw	s2,80(s1)
    800033f0:	a08d                	j	80003452 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033f2:	ff45849b          	addiw	s1,a1,-12
    800033f6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033fa:	0ff00793          	li	a5,255
    800033fe:	08e7e563          	bltu	a5,a4,80003488 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003402:	08052903          	lw	s2,128(a0)
    80003406:	00091d63          	bnez	s2,80003420 <bmap+0x70>
      addr = balloc(ip->dev);
    8000340a:	4108                	lw	a0,0(a0)
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	e6c080e7          	jalr	-404(ra) # 80003278 <balloc>
    80003414:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003418:	02090d63          	beqz	s2,80003452 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000341c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003420:	85ca                	mv	a1,s2
    80003422:	0009a503          	lw	a0,0(s3)
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	b90080e7          	jalr	-1136(ra) # 80002fb6 <bread>
    8000342e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003430:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003434:	02049593          	slli	a1,s1,0x20
    80003438:	9181                	srli	a1,a1,0x20
    8000343a:	058a                	slli	a1,a1,0x2
    8000343c:	00b784b3          	add	s1,a5,a1
    80003440:	0004a903          	lw	s2,0(s1)
    80003444:	02090063          	beqz	s2,80003464 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003448:	8552                	mv	a0,s4
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	c9c080e7          	jalr	-868(ra) # 800030e6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003452:	854a                	mv	a0,s2
    80003454:	70a2                	ld	ra,40(sp)
    80003456:	7402                	ld	s0,32(sp)
    80003458:	64e2                	ld	s1,24(sp)
    8000345a:	6942                	ld	s2,16(sp)
    8000345c:	69a2                	ld	s3,8(sp)
    8000345e:	6a02                	ld	s4,0(sp)
    80003460:	6145                	addi	sp,sp,48
    80003462:	8082                	ret
      addr = balloc(ip->dev);
    80003464:	0009a503          	lw	a0,0(s3)
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	e10080e7          	jalr	-496(ra) # 80003278 <balloc>
    80003470:	0005091b          	sext.w	s2,a0
      if(addr){
    80003474:	fc090ae3          	beqz	s2,80003448 <bmap+0x98>
        a[bn] = addr;
    80003478:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000347c:	8552                	mv	a0,s4
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	eec080e7          	jalr	-276(ra) # 8000436a <log_write>
    80003486:	b7c9                	j	80003448 <bmap+0x98>
  panic("bmap: out of range");
    80003488:	00005517          	auipc	a0,0x5
    8000348c:	0f050513          	addi	a0,a0,240 # 80008578 <syscalls+0x128>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	0b4080e7          	jalr	180(ra) # 80000544 <panic>

0000000080003498 <iget>:
{
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	e052                	sd	s4,0(sp)
    800034a6:	1800                	addi	s0,sp,48
    800034a8:	89aa                	mv	s3,a0
    800034aa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034ac:	0001c517          	auipc	a0,0x1c
    800034b0:	ddc50513          	addi	a0,a0,-548 # 8001f288 <itable>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	77e080e7          	jalr	1918(ra) # 80000c32 <acquire>
  empty = 0;
    800034bc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034be:	0001c497          	auipc	s1,0x1c
    800034c2:	de248493          	addi	s1,s1,-542 # 8001f2a0 <itable+0x18>
    800034c6:	0001e697          	auipc	a3,0x1e
    800034ca:	86a68693          	addi	a3,a3,-1942 # 80020d30 <log>
    800034ce:	a039                	j	800034dc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d0:	02090b63          	beqz	s2,80003506 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d4:	08848493          	addi	s1,s1,136
    800034d8:	02d48a63          	beq	s1,a3,8000350c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034dc:	449c                	lw	a5,8(s1)
    800034de:	fef059e3          	blez	a5,800034d0 <iget+0x38>
    800034e2:	4098                	lw	a4,0(s1)
    800034e4:	ff3716e3          	bne	a4,s3,800034d0 <iget+0x38>
    800034e8:	40d8                	lw	a4,4(s1)
    800034ea:	ff4713e3          	bne	a4,s4,800034d0 <iget+0x38>
      ip->ref++;
    800034ee:	2785                	addiw	a5,a5,1
    800034f0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034f2:	0001c517          	auipc	a0,0x1c
    800034f6:	d9650513          	addi	a0,a0,-618 # 8001f288 <itable>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	7ec080e7          	jalr	2028(ra) # 80000ce6 <release>
      return ip;
    80003502:	8926                	mv	s2,s1
    80003504:	a03d                	j	80003532 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003506:	f7f9                	bnez	a5,800034d4 <iget+0x3c>
    80003508:	8926                	mv	s2,s1
    8000350a:	b7e9                	j	800034d4 <iget+0x3c>
  if(empty == 0)
    8000350c:	02090c63          	beqz	s2,80003544 <iget+0xac>
  ip->dev = dev;
    80003510:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003514:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003518:	4785                	li	a5,1
    8000351a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003522:	0001c517          	auipc	a0,0x1c
    80003526:	d6650513          	addi	a0,a0,-666 # 8001f288 <itable>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	7bc080e7          	jalr	1980(ra) # 80000ce6 <release>
}
    80003532:	854a                	mv	a0,s2
    80003534:	70a2                	ld	ra,40(sp)
    80003536:	7402                	ld	s0,32(sp)
    80003538:	64e2                	ld	s1,24(sp)
    8000353a:	6942                	ld	s2,16(sp)
    8000353c:	69a2                	ld	s3,8(sp)
    8000353e:	6a02                	ld	s4,0(sp)
    80003540:	6145                	addi	sp,sp,48
    80003542:	8082                	ret
    panic("iget: no inodes");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	04c50513          	addi	a0,a0,76 # 80008590 <syscalls+0x140>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ff8080e7          	jalr	-8(ra) # 80000544 <panic>

0000000080003554 <fsinit>:
fsinit(int dev) {
    80003554:	7179                	addi	sp,sp,-48
    80003556:	f406                	sd	ra,40(sp)
    80003558:	f022                	sd	s0,32(sp)
    8000355a:	ec26                	sd	s1,24(sp)
    8000355c:	e84a                	sd	s2,16(sp)
    8000355e:	e44e                	sd	s3,8(sp)
    80003560:	1800                	addi	s0,sp,48
    80003562:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003564:	4585                	li	a1,1
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	a50080e7          	jalr	-1456(ra) # 80002fb6 <bread>
    8000356e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003570:	0001c997          	auipc	s3,0x1c
    80003574:	cf898993          	addi	s3,s3,-776 # 8001f268 <sb>
    80003578:	02000613          	li	a2,32
    8000357c:	05850593          	addi	a1,a0,88
    80003580:	854e                	mv	a0,s3
    80003582:	ffffe097          	auipc	ra,0xffffe
    80003586:	80c080e7          	jalr	-2036(ra) # 80000d8e <memmove>
  brelse(bp);
    8000358a:	8526                	mv	a0,s1
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	b5a080e7          	jalr	-1190(ra) # 800030e6 <brelse>
  if(sb.magic != FSMAGIC)
    80003594:	0009a703          	lw	a4,0(s3)
    80003598:	102037b7          	lui	a5,0x10203
    8000359c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035a0:	02f71263          	bne	a4,a5,800035c4 <fsinit+0x70>
  initlog(dev, &sb);
    800035a4:	0001c597          	auipc	a1,0x1c
    800035a8:	cc458593          	addi	a1,a1,-828 # 8001f268 <sb>
    800035ac:	854a                	mv	a0,s2
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	b40080e7          	jalr	-1216(ra) # 800040ee <initlog>
}
    800035b6:	70a2                	ld	ra,40(sp)
    800035b8:	7402                	ld	s0,32(sp)
    800035ba:	64e2                	ld	s1,24(sp)
    800035bc:	6942                	ld	s2,16(sp)
    800035be:	69a2                	ld	s3,8(sp)
    800035c0:	6145                	addi	sp,sp,48
    800035c2:	8082                	ret
    panic("invalid file system");
    800035c4:	00005517          	auipc	a0,0x5
    800035c8:	fdc50513          	addi	a0,a0,-36 # 800085a0 <syscalls+0x150>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	f78080e7          	jalr	-136(ra) # 80000544 <panic>

00000000800035d4 <iinit>:
{
    800035d4:	7179                	addi	sp,sp,-48
    800035d6:	f406                	sd	ra,40(sp)
    800035d8:	f022                	sd	s0,32(sp)
    800035da:	ec26                	sd	s1,24(sp)
    800035dc:	e84a                	sd	s2,16(sp)
    800035de:	e44e                	sd	s3,8(sp)
    800035e0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e2:	00005597          	auipc	a1,0x5
    800035e6:	fd658593          	addi	a1,a1,-42 # 800085b8 <syscalls+0x168>
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	c9e50513          	addi	a0,a0,-866 # 8001f288 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	5b0080e7          	jalr	1456(ra) # 80000ba2 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035fa:	0001c497          	auipc	s1,0x1c
    800035fe:	cb648493          	addi	s1,s1,-842 # 8001f2b0 <itable+0x28>
    80003602:	0001d997          	auipc	s3,0x1d
    80003606:	73e98993          	addi	s3,s3,1854 # 80020d40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000360a:	00005917          	auipc	s2,0x5
    8000360e:	fb690913          	addi	s2,s2,-74 # 800085c0 <syscalls+0x170>
    80003612:	85ca                	mv	a1,s2
    80003614:	8526                	mv	a0,s1
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	e3a080e7          	jalr	-454(ra) # 80004450 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361e:	08848493          	addi	s1,s1,136
    80003622:	ff3498e3          	bne	s1,s3,80003612 <iinit+0x3e>
}
    80003626:	70a2                	ld	ra,40(sp)
    80003628:	7402                	ld	s0,32(sp)
    8000362a:	64e2                	ld	s1,24(sp)
    8000362c:	6942                	ld	s2,16(sp)
    8000362e:	69a2                	ld	s3,8(sp)
    80003630:	6145                	addi	sp,sp,48
    80003632:	8082                	ret

0000000080003634 <ialloc>:
{
    80003634:	715d                	addi	sp,sp,-80
    80003636:	e486                	sd	ra,72(sp)
    80003638:	e0a2                	sd	s0,64(sp)
    8000363a:	fc26                	sd	s1,56(sp)
    8000363c:	f84a                	sd	s2,48(sp)
    8000363e:	f44e                	sd	s3,40(sp)
    80003640:	f052                	sd	s4,32(sp)
    80003642:	ec56                	sd	s5,24(sp)
    80003644:	e85a                	sd	s6,16(sp)
    80003646:	e45e                	sd	s7,8(sp)
    80003648:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364a:	0001c717          	auipc	a4,0x1c
    8000364e:	c2a72703          	lw	a4,-982(a4) # 8001f274 <sb+0xc>
    80003652:	4785                	li	a5,1
    80003654:	04e7fa63          	bgeu	a5,a4,800036a8 <ialloc+0x74>
    80003658:	8aaa                	mv	s5,a0
    8000365a:	8bae                	mv	s7,a1
    8000365c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365e:	0001ca17          	auipc	s4,0x1c
    80003662:	c0aa0a13          	addi	s4,s4,-1014 # 8001f268 <sb>
    80003666:	00048b1b          	sext.w	s6,s1
    8000366a:	0044d593          	srli	a1,s1,0x4
    8000366e:	018a2783          	lw	a5,24(s4)
    80003672:	9dbd                	addw	a1,a1,a5
    80003674:	8556                	mv	a0,s5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	940080e7          	jalr	-1728(ra) # 80002fb6 <bread>
    8000367e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003680:	05850993          	addi	s3,a0,88
    80003684:	00f4f793          	andi	a5,s1,15
    80003688:	079a                	slli	a5,a5,0x6
    8000368a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000368c:	00099783          	lh	a5,0(s3)
    80003690:	c3a1                	beqz	a5,800036d0 <ialloc+0x9c>
    brelse(bp);
    80003692:	00000097          	auipc	ra,0x0
    80003696:	a54080e7          	jalr	-1452(ra) # 800030e6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000369a:	0485                	addi	s1,s1,1
    8000369c:	00ca2703          	lw	a4,12(s4)
    800036a0:	0004879b          	sext.w	a5,s1
    800036a4:	fce7e1e3          	bltu	a5,a4,80003666 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	f2050513          	addi	a0,a0,-224 # 800085c8 <syscalls+0x178>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	ede080e7          	jalr	-290(ra) # 8000058e <printf>
  return 0;
    800036b8:	4501                	li	a0,0
}
    800036ba:	60a6                	ld	ra,72(sp)
    800036bc:	6406                	ld	s0,64(sp)
    800036be:	74e2                	ld	s1,56(sp)
    800036c0:	7942                	ld	s2,48(sp)
    800036c2:	79a2                	ld	s3,40(sp)
    800036c4:	7a02                	ld	s4,32(sp)
    800036c6:	6ae2                	ld	s5,24(sp)
    800036c8:	6b42                	ld	s6,16(sp)
    800036ca:	6ba2                	ld	s7,8(sp)
    800036cc:	6161                	addi	sp,sp,80
    800036ce:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036d0:	04000613          	li	a2,64
    800036d4:	4581                	li	a1,0
    800036d6:	854e                	mv	a0,s3
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	656080e7          	jalr	1622(ra) # 80000d2e <memset>
      dip->type = type;
    800036e0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036e4:	854a                	mv	a0,s2
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	c84080e7          	jalr	-892(ra) # 8000436a <log_write>
      brelse(bp);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	9f6080e7          	jalr	-1546(ra) # 800030e6 <brelse>
      return iget(dev, inum);
    800036f8:	85da                	mv	a1,s6
    800036fa:	8556                	mv	a0,s5
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	d9c080e7          	jalr	-612(ra) # 80003498 <iget>
    80003704:	bf5d                	j	800036ba <ialloc+0x86>

0000000080003706 <iupdate>:
{
    80003706:	1101                	addi	sp,sp,-32
    80003708:	ec06                	sd	ra,24(sp)
    8000370a:	e822                	sd	s0,16(sp)
    8000370c:	e426                	sd	s1,8(sp)
    8000370e:	e04a                	sd	s2,0(sp)
    80003710:	1000                	addi	s0,sp,32
    80003712:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003714:	415c                	lw	a5,4(a0)
    80003716:	0047d79b          	srliw	a5,a5,0x4
    8000371a:	0001c597          	auipc	a1,0x1c
    8000371e:	b665a583          	lw	a1,-1178(a1) # 8001f280 <sb+0x18>
    80003722:	9dbd                	addw	a1,a1,a5
    80003724:	4108                	lw	a0,0(a0)
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	890080e7          	jalr	-1904(ra) # 80002fb6 <bread>
    8000372e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003730:	05850793          	addi	a5,a0,88
    80003734:	40c8                	lw	a0,4(s1)
    80003736:	893d                	andi	a0,a0,15
    80003738:	051a                	slli	a0,a0,0x6
    8000373a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000373c:	04449703          	lh	a4,68(s1)
    80003740:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003744:	04649703          	lh	a4,70(s1)
    80003748:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000374c:	04849703          	lh	a4,72(s1)
    80003750:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003754:	04a49703          	lh	a4,74(s1)
    80003758:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000375c:	44f8                	lw	a4,76(s1)
    8000375e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003760:	03400613          	li	a2,52
    80003764:	05048593          	addi	a1,s1,80
    80003768:	0531                	addi	a0,a0,12
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	624080e7          	jalr	1572(ra) # 80000d8e <memmove>
  log_write(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00001097          	auipc	ra,0x1
    80003778:	bf6080e7          	jalr	-1034(ra) # 8000436a <log_write>
  brelse(bp);
    8000377c:	854a                	mv	a0,s2
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	968080e7          	jalr	-1688(ra) # 800030e6 <brelse>
}
    80003786:	60e2                	ld	ra,24(sp)
    80003788:	6442                	ld	s0,16(sp)
    8000378a:	64a2                	ld	s1,8(sp)
    8000378c:	6902                	ld	s2,0(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <idup>:
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	1000                	addi	s0,sp,32
    8000379c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000379e:	0001c517          	auipc	a0,0x1c
    800037a2:	aea50513          	addi	a0,a0,-1302 # 8001f288 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	48c080e7          	jalr	1164(ra) # 80000c32 <acquire>
  ip->ref++;
    800037ae:	449c                	lw	a5,8(s1)
    800037b0:	2785                	addiw	a5,a5,1
    800037b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037b4:	0001c517          	auipc	a0,0x1c
    800037b8:	ad450513          	addi	a0,a0,-1324 # 8001f288 <itable>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	52a080e7          	jalr	1322(ra) # 80000ce6 <release>
}
    800037c4:	8526                	mv	a0,s1
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6105                	addi	sp,sp,32
    800037ce:	8082                	ret

00000000800037d0 <ilock>:
{
    800037d0:	1101                	addi	sp,sp,-32
    800037d2:	ec06                	sd	ra,24(sp)
    800037d4:	e822                	sd	s0,16(sp)
    800037d6:	e426                	sd	s1,8(sp)
    800037d8:	e04a                	sd	s2,0(sp)
    800037da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037dc:	c115                	beqz	a0,80003800 <ilock+0x30>
    800037de:	84aa                	mv	s1,a0
    800037e0:	451c                	lw	a5,8(a0)
    800037e2:	00f05f63          	blez	a5,80003800 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e6:	0541                	addi	a0,a0,16
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	ca2080e7          	jalr	-862(ra) # 8000448a <acquiresleep>
  if(ip->valid == 0){
    800037f0:	40bc                	lw	a5,64(s1)
    800037f2:	cf99                	beqz	a5,80003810 <ilock+0x40>
}
    800037f4:	60e2                	ld	ra,24(sp)
    800037f6:	6442                	ld	s0,16(sp)
    800037f8:	64a2                	ld	s1,8(sp)
    800037fa:	6902                	ld	s2,0(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret
    panic("ilock");
    80003800:	00005517          	auipc	a0,0x5
    80003804:	de050513          	addi	a0,a0,-544 # 800085e0 <syscalls+0x190>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	d3c080e7          	jalr	-708(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003810:	40dc                	lw	a5,4(s1)
    80003812:	0047d79b          	srliw	a5,a5,0x4
    80003816:	0001c597          	auipc	a1,0x1c
    8000381a:	a6a5a583          	lw	a1,-1430(a1) # 8001f280 <sb+0x18>
    8000381e:	9dbd                	addw	a1,a1,a5
    80003820:	4088                	lw	a0,0(s1)
    80003822:	fffff097          	auipc	ra,0xfffff
    80003826:	794080e7          	jalr	1940(ra) # 80002fb6 <bread>
    8000382a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382c:	05850593          	addi	a1,a0,88
    80003830:	40dc                	lw	a5,4(s1)
    80003832:	8bbd                	andi	a5,a5,15
    80003834:	079a                	slli	a5,a5,0x6
    80003836:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003838:	00059783          	lh	a5,0(a1)
    8000383c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003840:	00259783          	lh	a5,2(a1)
    80003844:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003848:	00459783          	lh	a5,4(a1)
    8000384c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003850:	00659783          	lh	a5,6(a1)
    80003854:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003858:	459c                	lw	a5,8(a1)
    8000385a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000385c:	03400613          	li	a2,52
    80003860:	05b1                	addi	a1,a1,12
    80003862:	05048513          	addi	a0,s1,80
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	528080e7          	jalr	1320(ra) # 80000d8e <memmove>
    brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	876080e7          	jalr	-1930(ra) # 800030e6 <brelse>
    ip->valid = 1;
    80003878:	4785                	li	a5,1
    8000387a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000387c:	04449783          	lh	a5,68(s1)
    80003880:	fbb5                	bnez	a5,800037f4 <ilock+0x24>
      panic("ilock: no type");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	d6650513          	addi	a0,a0,-666 # 800085e8 <syscalls+0x198>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cba080e7          	jalr	-838(ra) # 80000544 <panic>

0000000080003892 <iunlock>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	e04a                	sd	s2,0(sp)
    8000389c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389e:	c905                	beqz	a0,800038ce <iunlock+0x3c>
    800038a0:	84aa                	mv	s1,a0
    800038a2:	01050913          	addi	s2,a0,16
    800038a6:	854a                	mv	a0,s2
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	c7c080e7          	jalr	-900(ra) # 80004524 <holdingsleep>
    800038b0:	cd19                	beqz	a0,800038ce <iunlock+0x3c>
    800038b2:	449c                	lw	a5,8(s1)
    800038b4:	00f05d63          	blez	a5,800038ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	c26080e7          	jalr	-986(ra) # 800044e0 <releasesleep>
}
    800038c2:	60e2                	ld	ra,24(sp)
    800038c4:	6442                	ld	s0,16(sp)
    800038c6:	64a2                	ld	s1,8(sp)
    800038c8:	6902                	ld	s2,0(sp)
    800038ca:	6105                	addi	sp,sp,32
    800038cc:	8082                	ret
    panic("iunlock");
    800038ce:	00005517          	auipc	a0,0x5
    800038d2:	d2a50513          	addi	a0,a0,-726 # 800085f8 <syscalls+0x1a8>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c6e080e7          	jalr	-914(ra) # 80000544 <panic>

00000000800038de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038de:	7179                	addi	sp,sp,-48
    800038e0:	f406                	sd	ra,40(sp)
    800038e2:	f022                	sd	s0,32(sp)
    800038e4:	ec26                	sd	s1,24(sp)
    800038e6:	e84a                	sd	s2,16(sp)
    800038e8:	e44e                	sd	s3,8(sp)
    800038ea:	e052                	sd	s4,0(sp)
    800038ec:	1800                	addi	s0,sp,48
    800038ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038f0:	05050493          	addi	s1,a0,80
    800038f4:	08050913          	addi	s2,a0,128
    800038f8:	a021                	j	80003900 <itrunc+0x22>
    800038fa:	0491                	addi	s1,s1,4
    800038fc:	01248d63          	beq	s1,s2,80003916 <itrunc+0x38>
    if(ip->addrs[i]){
    80003900:	408c                	lw	a1,0(s1)
    80003902:	dde5                	beqz	a1,800038fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	8f4080e7          	jalr	-1804(ra) # 800031fc <bfree>
      ip->addrs[i] = 0;
    80003910:	0004a023          	sw	zero,0(s1)
    80003914:	b7dd                	j	800038fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003916:	0809a583          	lw	a1,128(s3)
    8000391a:	e185                	bnez	a1,8000393a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000391c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003920:	854e                	mv	a0,s3
    80003922:	00000097          	auipc	ra,0x0
    80003926:	de4080e7          	jalr	-540(ra) # 80003706 <iupdate>
}
    8000392a:	70a2                	ld	ra,40(sp)
    8000392c:	7402                	ld	s0,32(sp)
    8000392e:	64e2                	ld	s1,24(sp)
    80003930:	6942                	ld	s2,16(sp)
    80003932:	69a2                	ld	s3,8(sp)
    80003934:	6a02                	ld	s4,0(sp)
    80003936:	6145                	addi	sp,sp,48
    80003938:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	fffff097          	auipc	ra,0xfffff
    80003942:	678080e7          	jalr	1656(ra) # 80002fb6 <bread>
    80003946:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003948:	05850493          	addi	s1,a0,88
    8000394c:	45850913          	addi	s2,a0,1112
    80003950:	a811                	j	80003964 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003952:	0009a503          	lw	a0,0(s3)
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	8a6080e7          	jalr	-1882(ra) # 800031fc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395e:	0491                	addi	s1,s1,4
    80003960:	01248563          	beq	s1,s2,8000396a <itrunc+0x8c>
      if(a[j])
    80003964:	408c                	lw	a1,0(s1)
    80003966:	dde5                	beqz	a1,8000395e <itrunc+0x80>
    80003968:	b7ed                	j	80003952 <itrunc+0x74>
    brelse(bp);
    8000396a:	8552                	mv	a0,s4
    8000396c:	fffff097          	auipc	ra,0xfffff
    80003970:	77a080e7          	jalr	1914(ra) # 800030e6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003974:	0809a583          	lw	a1,128(s3)
    80003978:	0009a503          	lw	a0,0(s3)
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	880080e7          	jalr	-1920(ra) # 800031fc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003984:	0809a023          	sw	zero,128(s3)
    80003988:	bf51                	j	8000391c <itrunc+0x3e>

000000008000398a <iput>:
{
    8000398a:	1101                	addi	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	e426                	sd	s1,8(sp)
    80003992:	e04a                	sd	s2,0(sp)
    80003994:	1000                	addi	s0,sp,32
    80003996:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003998:	0001c517          	auipc	a0,0x1c
    8000399c:	8f050513          	addi	a0,a0,-1808 # 8001f288 <itable>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	292080e7          	jalr	658(ra) # 80000c32 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a8:	4498                	lw	a4,8(s1)
    800039aa:	4785                	li	a5,1
    800039ac:	02f70363          	beq	a4,a5,800039d2 <iput+0x48>
  ip->ref--;
    800039b0:	449c                	lw	a5,8(s1)
    800039b2:	37fd                	addiw	a5,a5,-1
    800039b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b6:	0001c517          	auipc	a0,0x1c
    800039ba:	8d250513          	addi	a0,a0,-1838 # 8001f288 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	328080e7          	jalr	808(ra) # 80000ce6 <release>
}
    800039c6:	60e2                	ld	ra,24(sp)
    800039c8:	6442                	ld	s0,16(sp)
    800039ca:	64a2                	ld	s1,8(sp)
    800039cc:	6902                	ld	s2,0(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d2:	40bc                	lw	a5,64(s1)
    800039d4:	dff1                	beqz	a5,800039b0 <iput+0x26>
    800039d6:	04a49783          	lh	a5,74(s1)
    800039da:	fbf9                	bnez	a5,800039b0 <iput+0x26>
    acquiresleep(&ip->lock);
    800039dc:	01048913          	addi	s2,s1,16
    800039e0:	854a                	mv	a0,s2
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	aa8080e7          	jalr	-1368(ra) # 8000448a <acquiresleep>
    release(&itable.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	89e50513          	addi	a0,a0,-1890 # 8001f288 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	2f4080e7          	jalr	756(ra) # 80000ce6 <release>
    itrunc(ip);
    800039fa:	8526                	mv	a0,s1
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	ee2080e7          	jalr	-286(ra) # 800038de <itrunc>
    ip->type = 0;
    80003a04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	cfc080e7          	jalr	-772(ra) # 80003706 <iupdate>
    ip->valid = 0;
    80003a12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	ac8080e7          	jalr	-1336(ra) # 800044e0 <releasesleep>
    acquire(&itable.lock);
    80003a20:	0001c517          	auipc	a0,0x1c
    80003a24:	86850513          	addi	a0,a0,-1944 # 8001f288 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	20a080e7          	jalr	522(ra) # 80000c32 <acquire>
    80003a30:	b741                	j	800039b0 <iput+0x26>

0000000080003a32 <iunlockput>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	1000                	addi	s0,sp,32
    80003a3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	e54080e7          	jalr	-428(ra) # 80003892 <iunlock>
  iput(ip);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	f42080e7          	jalr	-190(ra) # 8000398a <iput>
}
    80003a50:	60e2                	ld	ra,24(sp)
    80003a52:	6442                	ld	s0,16(sp)
    80003a54:	64a2                	ld	s1,8(sp)
    80003a56:	6105                	addi	sp,sp,32
    80003a58:	8082                	ret

0000000080003a5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a5a:	1141                	addi	sp,sp,-16
    80003a5c:	e422                	sd	s0,8(sp)
    80003a5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a60:	411c                	lw	a5,0(a0)
    80003a62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a64:	415c                	lw	a5,4(a0)
    80003a66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a68:	04451783          	lh	a5,68(a0)
    80003a6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a70:	04a51783          	lh	a5,74(a0)
    80003a74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a78:	04c56783          	lwu	a5,76(a0)
    80003a7c:	e99c                	sd	a5,16(a1)
}
    80003a7e:	6422                	ld	s0,8(sp)
    80003a80:	0141                	addi	sp,sp,16
    80003a82:	8082                	ret

0000000080003a84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a84:	457c                	lw	a5,76(a0)
    80003a86:	0ed7e963          	bltu	a5,a3,80003b78 <readi+0xf4>
{
    80003a8a:	7159                	addi	sp,sp,-112
    80003a8c:	f486                	sd	ra,104(sp)
    80003a8e:	f0a2                	sd	s0,96(sp)
    80003a90:	eca6                	sd	s1,88(sp)
    80003a92:	e8ca                	sd	s2,80(sp)
    80003a94:	e4ce                	sd	s3,72(sp)
    80003a96:	e0d2                	sd	s4,64(sp)
    80003a98:	fc56                	sd	s5,56(sp)
    80003a9a:	f85a                	sd	s6,48(sp)
    80003a9c:	f45e                	sd	s7,40(sp)
    80003a9e:	f062                	sd	s8,32(sp)
    80003aa0:	ec66                	sd	s9,24(sp)
    80003aa2:	e86a                	sd	s10,16(sp)
    80003aa4:	e46e                	sd	s11,8(sp)
    80003aa6:	1880                	addi	s0,sp,112
    80003aa8:	8b2a                	mv	s6,a0
    80003aaa:	8bae                	mv	s7,a1
    80003aac:	8a32                	mv	s4,a2
    80003aae:	84b6                	mv	s1,a3
    80003ab0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ab2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab6:	0ad76063          	bltu	a4,a3,80003b56 <readi+0xd2>
  if(off + n > ip->size)
    80003aba:	00e7f463          	bgeu	a5,a4,80003ac2 <readi+0x3e>
    n = ip->size - off;
    80003abe:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac2:	0a0a8963          	beqz	s5,80003b74 <readi+0xf0>
    80003ac6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003acc:	5c7d                	li	s8,-1
    80003ace:	a82d                	j	80003b08 <readi+0x84>
    80003ad0:	020d1d93          	slli	s11,s10,0x20
    80003ad4:	020ddd93          	srli	s11,s11,0x20
    80003ad8:	05890613          	addi	a2,s2,88
    80003adc:	86ee                	mv	a3,s11
    80003ade:	963a                	add	a2,a2,a4
    80003ae0:	85d2                	mv	a1,s4
    80003ae2:	855e                	mv	a0,s7
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	9da080e7          	jalr	-1574(ra) # 800024be <either_copyout>
    80003aec:	05850d63          	beq	a0,s8,80003b46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003af0:	854a                	mv	a0,s2
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	5f4080e7          	jalr	1524(ra) # 800030e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003afa:	013d09bb          	addw	s3,s10,s3
    80003afe:	009d04bb          	addw	s1,s10,s1
    80003b02:	9a6e                	add	s4,s4,s11
    80003b04:	0559f763          	bgeu	s3,s5,80003b52 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b08:	00a4d59b          	srliw	a1,s1,0xa
    80003b0c:	855a                	mv	a0,s6
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	8a2080e7          	jalr	-1886(ra) # 800033b0 <bmap>
    80003b16:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b1a:	cd85                	beqz	a1,80003b52 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b1c:	000b2503          	lw	a0,0(s6)
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	496080e7          	jalr	1174(ra) # 80002fb6 <bread>
    80003b28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2a:	3ff4f713          	andi	a4,s1,1023
    80003b2e:	40ec87bb          	subw	a5,s9,a4
    80003b32:	413a86bb          	subw	a3,s5,s3
    80003b36:	8d3e                	mv	s10,a5
    80003b38:	2781                	sext.w	a5,a5
    80003b3a:	0006861b          	sext.w	a2,a3
    80003b3e:	f8f679e3          	bgeu	a2,a5,80003ad0 <readi+0x4c>
    80003b42:	8d36                	mv	s10,a3
    80003b44:	b771                	j	80003ad0 <readi+0x4c>
      brelse(bp);
    80003b46:	854a                	mv	a0,s2
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	59e080e7          	jalr	1438(ra) # 800030e6 <brelse>
      tot = -1;
    80003b50:	59fd                	li	s3,-1
  }
  return tot;
    80003b52:	0009851b          	sext.w	a0,s3
}
    80003b56:	70a6                	ld	ra,104(sp)
    80003b58:	7406                	ld	s0,96(sp)
    80003b5a:	64e6                	ld	s1,88(sp)
    80003b5c:	6946                	ld	s2,80(sp)
    80003b5e:	69a6                	ld	s3,72(sp)
    80003b60:	6a06                	ld	s4,64(sp)
    80003b62:	7ae2                	ld	s5,56(sp)
    80003b64:	7b42                	ld	s6,48(sp)
    80003b66:	7ba2                	ld	s7,40(sp)
    80003b68:	7c02                	ld	s8,32(sp)
    80003b6a:	6ce2                	ld	s9,24(sp)
    80003b6c:	6d42                	ld	s10,16(sp)
    80003b6e:	6da2                	ld	s11,8(sp)
    80003b70:	6165                	addi	sp,sp,112
    80003b72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b74:	89d6                	mv	s3,s5
    80003b76:	bff1                	j	80003b52 <readi+0xce>
    return 0;
    80003b78:	4501                	li	a0,0
}
    80003b7a:	8082                	ret

0000000080003b7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b7c:	457c                	lw	a5,76(a0)
    80003b7e:	10d7e863          	bltu	a5,a3,80003c8e <writei+0x112>
{
    80003b82:	7159                	addi	sp,sp,-112
    80003b84:	f486                	sd	ra,104(sp)
    80003b86:	f0a2                	sd	s0,96(sp)
    80003b88:	eca6                	sd	s1,88(sp)
    80003b8a:	e8ca                	sd	s2,80(sp)
    80003b8c:	e4ce                	sd	s3,72(sp)
    80003b8e:	e0d2                	sd	s4,64(sp)
    80003b90:	fc56                	sd	s5,56(sp)
    80003b92:	f85a                	sd	s6,48(sp)
    80003b94:	f45e                	sd	s7,40(sp)
    80003b96:	f062                	sd	s8,32(sp)
    80003b98:	ec66                	sd	s9,24(sp)
    80003b9a:	e86a                	sd	s10,16(sp)
    80003b9c:	e46e                	sd	s11,8(sp)
    80003b9e:	1880                	addi	s0,sp,112
    80003ba0:	8aaa                	mv	s5,a0
    80003ba2:	8bae                	mv	s7,a1
    80003ba4:	8a32                	mv	s4,a2
    80003ba6:	8936                	mv	s2,a3
    80003ba8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003baa:	00e687bb          	addw	a5,a3,a4
    80003bae:	0ed7e263          	bltu	a5,a3,80003c92 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bb2:	00043737          	lui	a4,0x43
    80003bb6:	0ef76063          	bltu	a4,a5,80003c96 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bba:	0c0b0863          	beqz	s6,80003c8a <writei+0x10e>
    80003bbe:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc4:	5c7d                	li	s8,-1
    80003bc6:	a091                	j	80003c0a <writei+0x8e>
    80003bc8:	020d1d93          	slli	s11,s10,0x20
    80003bcc:	020ddd93          	srli	s11,s11,0x20
    80003bd0:	05848513          	addi	a0,s1,88
    80003bd4:	86ee                	mv	a3,s11
    80003bd6:	8652                	mv	a2,s4
    80003bd8:	85de                	mv	a1,s7
    80003bda:	953a                	add	a0,a0,a4
    80003bdc:	fffff097          	auipc	ra,0xfffff
    80003be0:	938080e7          	jalr	-1736(ra) # 80002514 <either_copyin>
    80003be4:	07850263          	beq	a0,s8,80003c48 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	780080e7          	jalr	1920(ra) # 8000436a <log_write>
    brelse(bp);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	4f2080e7          	jalr	1266(ra) # 800030e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bfc:	013d09bb          	addw	s3,s10,s3
    80003c00:	012d093b          	addw	s2,s10,s2
    80003c04:	9a6e                	add	s4,s4,s11
    80003c06:	0569f663          	bgeu	s3,s6,80003c52 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c0a:	00a9559b          	srliw	a1,s2,0xa
    80003c0e:	8556                	mv	a0,s5
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	7a0080e7          	jalr	1952(ra) # 800033b0 <bmap>
    80003c18:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c1c:	c99d                	beqz	a1,80003c52 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c1e:	000aa503          	lw	a0,0(s5)
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	394080e7          	jalr	916(ra) # 80002fb6 <bread>
    80003c2a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2c:	3ff97713          	andi	a4,s2,1023
    80003c30:	40ec87bb          	subw	a5,s9,a4
    80003c34:	413b06bb          	subw	a3,s6,s3
    80003c38:	8d3e                	mv	s10,a5
    80003c3a:	2781                	sext.w	a5,a5
    80003c3c:	0006861b          	sext.w	a2,a3
    80003c40:	f8f674e3          	bgeu	a2,a5,80003bc8 <writei+0x4c>
    80003c44:	8d36                	mv	s10,a3
    80003c46:	b749                	j	80003bc8 <writei+0x4c>
      brelse(bp);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	fffff097          	auipc	ra,0xfffff
    80003c4e:	49c080e7          	jalr	1180(ra) # 800030e6 <brelse>
  }

  if(off > ip->size)
    80003c52:	04caa783          	lw	a5,76(s5)
    80003c56:	0127f463          	bgeu	a5,s2,80003c5e <writei+0xe2>
    ip->size = off;
    80003c5a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c5e:	8556                	mv	a0,s5
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	aa6080e7          	jalr	-1370(ra) # 80003706 <iupdate>

  return tot;
    80003c68:	0009851b          	sext.w	a0,s3
}
    80003c6c:	70a6                	ld	ra,104(sp)
    80003c6e:	7406                	ld	s0,96(sp)
    80003c70:	64e6                	ld	s1,88(sp)
    80003c72:	6946                	ld	s2,80(sp)
    80003c74:	69a6                	ld	s3,72(sp)
    80003c76:	6a06                	ld	s4,64(sp)
    80003c78:	7ae2                	ld	s5,56(sp)
    80003c7a:	7b42                	ld	s6,48(sp)
    80003c7c:	7ba2                	ld	s7,40(sp)
    80003c7e:	7c02                	ld	s8,32(sp)
    80003c80:	6ce2                	ld	s9,24(sp)
    80003c82:	6d42                	ld	s10,16(sp)
    80003c84:	6da2                	ld	s11,8(sp)
    80003c86:	6165                	addi	sp,sp,112
    80003c88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c8a:	89da                	mv	s3,s6
    80003c8c:	bfc9                	j	80003c5e <writei+0xe2>
    return -1;
    80003c8e:	557d                	li	a0,-1
}
    80003c90:	8082                	ret
    return -1;
    80003c92:	557d                	li	a0,-1
    80003c94:	bfe1                	j	80003c6c <writei+0xf0>
    return -1;
    80003c96:	557d                	li	a0,-1
    80003c98:	bfd1                	j	80003c6c <writei+0xf0>

0000000080003c9a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c9a:	1141                	addi	sp,sp,-16
    80003c9c:	e406                	sd	ra,8(sp)
    80003c9e:	e022                	sd	s0,0(sp)
    80003ca0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ca2:	4639                	li	a2,14
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	162080e7          	jalr	354(ra) # 80000e06 <strncmp>
}
    80003cac:	60a2                	ld	ra,8(sp)
    80003cae:	6402                	ld	s0,0(sp)
    80003cb0:	0141                	addi	sp,sp,16
    80003cb2:	8082                	ret

0000000080003cb4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cb4:	7139                	addi	sp,sp,-64
    80003cb6:	fc06                	sd	ra,56(sp)
    80003cb8:	f822                	sd	s0,48(sp)
    80003cba:	f426                	sd	s1,40(sp)
    80003cbc:	f04a                	sd	s2,32(sp)
    80003cbe:	ec4e                	sd	s3,24(sp)
    80003cc0:	e852                	sd	s4,16(sp)
    80003cc2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cc4:	04451703          	lh	a4,68(a0)
    80003cc8:	4785                	li	a5,1
    80003cca:	00f71a63          	bne	a4,a5,80003cde <dirlookup+0x2a>
    80003cce:	892a                	mv	s2,a0
    80003cd0:	89ae                	mv	s3,a1
    80003cd2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd4:	457c                	lw	a5,76(a0)
    80003cd6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cda:	e79d                	bnez	a5,80003d08 <dirlookup+0x54>
    80003cdc:	a8a5                	j	80003d54 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cde:	00005517          	auipc	a0,0x5
    80003ce2:	92250513          	addi	a0,a0,-1758 # 80008600 <syscalls+0x1b0>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	85e080e7          	jalr	-1954(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cee:	00005517          	auipc	a0,0x5
    80003cf2:	92a50513          	addi	a0,a0,-1750 # 80008618 <syscalls+0x1c8>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	84e080e7          	jalr	-1970(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	24c1                	addiw	s1,s1,16
    80003d00:	04c92783          	lw	a5,76(s2)
    80003d04:	04f4f763          	bgeu	s1,a5,80003d52 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d08:	4741                	li	a4,16
    80003d0a:	86a6                	mv	a3,s1
    80003d0c:	fc040613          	addi	a2,s0,-64
    80003d10:	4581                	li	a1,0
    80003d12:	854a                	mv	a0,s2
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	d70080e7          	jalr	-656(ra) # 80003a84 <readi>
    80003d1c:	47c1                	li	a5,16
    80003d1e:	fcf518e3          	bne	a0,a5,80003cee <dirlookup+0x3a>
    if(de.inum == 0)
    80003d22:	fc045783          	lhu	a5,-64(s0)
    80003d26:	dfe1                	beqz	a5,80003cfe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d28:	fc240593          	addi	a1,s0,-62
    80003d2c:	854e                	mv	a0,s3
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	f6c080e7          	jalr	-148(ra) # 80003c9a <namecmp>
    80003d36:	f561                	bnez	a0,80003cfe <dirlookup+0x4a>
      if(poff)
    80003d38:	000a0463          	beqz	s4,80003d40 <dirlookup+0x8c>
        *poff = off;
    80003d3c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d40:	fc045583          	lhu	a1,-64(s0)
    80003d44:	00092503          	lw	a0,0(s2)
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	750080e7          	jalr	1872(ra) # 80003498 <iget>
    80003d50:	a011                	j	80003d54 <dirlookup+0xa0>
  return 0;
    80003d52:	4501                	li	a0,0
}
    80003d54:	70e2                	ld	ra,56(sp)
    80003d56:	7442                	ld	s0,48(sp)
    80003d58:	74a2                	ld	s1,40(sp)
    80003d5a:	7902                	ld	s2,32(sp)
    80003d5c:	69e2                	ld	s3,24(sp)
    80003d5e:	6a42                	ld	s4,16(sp)
    80003d60:	6121                	addi	sp,sp,64
    80003d62:	8082                	ret

0000000080003d64 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d64:	711d                	addi	sp,sp,-96
    80003d66:	ec86                	sd	ra,88(sp)
    80003d68:	e8a2                	sd	s0,80(sp)
    80003d6a:	e4a6                	sd	s1,72(sp)
    80003d6c:	e0ca                	sd	s2,64(sp)
    80003d6e:	fc4e                	sd	s3,56(sp)
    80003d70:	f852                	sd	s4,48(sp)
    80003d72:	f456                	sd	s5,40(sp)
    80003d74:	f05a                	sd	s6,32(sp)
    80003d76:	ec5e                	sd	s7,24(sp)
    80003d78:	e862                	sd	s8,16(sp)
    80003d7a:	e466                	sd	s9,8(sp)
    80003d7c:	1080                	addi	s0,sp,96
    80003d7e:	84aa                	mv	s1,a0
    80003d80:	8b2e                	mv	s6,a1
    80003d82:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d84:	00054703          	lbu	a4,0(a0)
    80003d88:	02f00793          	li	a5,47
    80003d8c:	02f70363          	beq	a4,a5,80003db2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d90:	ffffe097          	auipc	ra,0xffffe
    80003d94:	c7e080e7          	jalr	-898(ra) # 80001a0e <myproc>
    80003d98:	15053503          	ld	a0,336(a0)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	9f6080e7          	jalr	-1546(ra) # 80003792 <idup>
    80003da4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003da6:	02f00913          	li	s2,47
  len = path - s;
    80003daa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dae:	4c05                	li	s8,1
    80003db0:	a865                	j	80003e68 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003db2:	4585                	li	a1,1
    80003db4:	4505                	li	a0,1
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	6e2080e7          	jalr	1762(ra) # 80003498 <iget>
    80003dbe:	89aa                	mv	s3,a0
    80003dc0:	b7dd                	j	80003da6 <namex+0x42>
      iunlockput(ip);
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	c6e080e7          	jalr	-914(ra) # 80003a32 <iunlockput>
      return 0;
    80003dcc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dce:	854e                	mv	a0,s3
    80003dd0:	60e6                	ld	ra,88(sp)
    80003dd2:	6446                	ld	s0,80(sp)
    80003dd4:	64a6                	ld	s1,72(sp)
    80003dd6:	6906                	ld	s2,64(sp)
    80003dd8:	79e2                	ld	s3,56(sp)
    80003dda:	7a42                	ld	s4,48(sp)
    80003ddc:	7aa2                	ld	s5,40(sp)
    80003dde:	7b02                	ld	s6,32(sp)
    80003de0:	6be2                	ld	s7,24(sp)
    80003de2:	6c42                	ld	s8,16(sp)
    80003de4:	6ca2                	ld	s9,8(sp)
    80003de6:	6125                	addi	sp,sp,96
    80003de8:	8082                	ret
      iunlock(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	aa6080e7          	jalr	-1370(ra) # 80003892 <iunlock>
      return ip;
    80003df4:	bfe9                	j	80003dce <namex+0x6a>
      iunlockput(ip);
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	c3a080e7          	jalr	-966(ra) # 80003a32 <iunlockput>
      return 0;
    80003e00:	89d2                	mv	s3,s4
    80003e02:	b7f1                	j	80003dce <namex+0x6a>
  len = path - s;
    80003e04:	40b48633          	sub	a2,s1,a1
    80003e08:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e0c:	094cd463          	bge	s9,s4,80003e94 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e10:	4639                	li	a2,14
    80003e12:	8556                	mv	a0,s5
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	f7a080e7          	jalr	-134(ra) # 80000d8e <memmove>
  while(*path == '/')
    80003e1c:	0004c783          	lbu	a5,0(s1)
    80003e20:	01279763          	bne	a5,s2,80003e2e <namex+0xca>
    path++;
    80003e24:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	ff278de3          	beq	a5,s2,80003e24 <namex+0xc0>
    ilock(ip);
    80003e2e:	854e                	mv	a0,s3
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	9a0080e7          	jalr	-1632(ra) # 800037d0 <ilock>
    if(ip->type != T_DIR){
    80003e38:	04499783          	lh	a5,68(s3)
    80003e3c:	f98793e3          	bne	a5,s8,80003dc2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e40:	000b0563          	beqz	s6,80003e4a <namex+0xe6>
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	d3cd                	beqz	a5,80003dea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e4a:	865e                	mv	a2,s7
    80003e4c:	85d6                	mv	a1,s5
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	e64080e7          	jalr	-412(ra) # 80003cb4 <dirlookup>
    80003e58:	8a2a                	mv	s4,a0
    80003e5a:	dd51                	beqz	a0,80003df6 <namex+0x92>
    iunlockput(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	bd4080e7          	jalr	-1068(ra) # 80003a32 <iunlockput>
    ip = next;
    80003e66:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e68:	0004c783          	lbu	a5,0(s1)
    80003e6c:	05279763          	bne	a5,s2,80003eba <namex+0x156>
    path++;
    80003e70:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e72:	0004c783          	lbu	a5,0(s1)
    80003e76:	ff278de3          	beq	a5,s2,80003e70 <namex+0x10c>
  if(*path == 0)
    80003e7a:	c79d                	beqz	a5,80003ea8 <namex+0x144>
    path++;
    80003e7c:	85a6                	mv	a1,s1
  len = path - s;
    80003e7e:	8a5e                	mv	s4,s7
    80003e80:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e82:	01278963          	beq	a5,s2,80003e94 <namex+0x130>
    80003e86:	dfbd                	beqz	a5,80003e04 <namex+0xa0>
    path++;
    80003e88:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	ff279ce3          	bne	a5,s2,80003e86 <namex+0x122>
    80003e92:	bf8d                	j	80003e04 <namex+0xa0>
    memmove(name, s, len);
    80003e94:	2601                	sext.w	a2,a2
    80003e96:	8556                	mv	a0,s5
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	ef6080e7          	jalr	-266(ra) # 80000d8e <memmove>
    name[len] = 0;
    80003ea0:	9a56                	add	s4,s4,s5
    80003ea2:	000a0023          	sb	zero,0(s4)
    80003ea6:	bf9d                	j	80003e1c <namex+0xb8>
  if(nameiparent){
    80003ea8:	f20b03e3          	beqz	s6,80003dce <namex+0x6a>
    iput(ip);
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	adc080e7          	jalr	-1316(ra) # 8000398a <iput>
    return 0;
    80003eb6:	4981                	li	s3,0
    80003eb8:	bf19                	j	80003dce <namex+0x6a>
  if(*path == 0)
    80003eba:	d7fd                	beqz	a5,80003ea8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	85a6                	mv	a1,s1
    80003ec2:	b7d1                	j	80003e86 <namex+0x122>

0000000080003ec4 <dirlink>:
{
    80003ec4:	7139                	addi	sp,sp,-64
    80003ec6:	fc06                	sd	ra,56(sp)
    80003ec8:	f822                	sd	s0,48(sp)
    80003eca:	f426                	sd	s1,40(sp)
    80003ecc:	f04a                	sd	s2,32(sp)
    80003ece:	ec4e                	sd	s3,24(sp)
    80003ed0:	e852                	sd	s4,16(sp)
    80003ed2:	0080                	addi	s0,sp,64
    80003ed4:	892a                	mv	s2,a0
    80003ed6:	8a2e                	mv	s4,a1
    80003ed8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eda:	4601                	li	a2,0
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	dd8080e7          	jalr	-552(ra) # 80003cb4 <dirlookup>
    80003ee4:	e93d                	bnez	a0,80003f5a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	04c92483          	lw	s1,76(s2)
    80003eea:	c49d                	beqz	s1,80003f18 <dirlink+0x54>
    80003eec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eee:	4741                	li	a4,16
    80003ef0:	86a6                	mv	a3,s1
    80003ef2:	fc040613          	addi	a2,s0,-64
    80003ef6:	4581                	li	a1,0
    80003ef8:	854a                	mv	a0,s2
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	b8a080e7          	jalr	-1142(ra) # 80003a84 <readi>
    80003f02:	47c1                	li	a5,16
    80003f04:	06f51163          	bne	a0,a5,80003f66 <dirlink+0xa2>
    if(de.inum == 0)
    80003f08:	fc045783          	lhu	a5,-64(s0)
    80003f0c:	c791                	beqz	a5,80003f18 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0e:	24c1                	addiw	s1,s1,16
    80003f10:	04c92783          	lw	a5,76(s2)
    80003f14:	fcf4ede3          	bltu	s1,a5,80003eee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f18:	4639                	li	a2,14
    80003f1a:	85d2                	mv	a1,s4
    80003f1c:	fc240513          	addi	a0,s0,-62
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	f22080e7          	jalr	-222(ra) # 80000e42 <strncpy>
  de.inum = inum;
    80003f28:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2c:	4741                	li	a4,16
    80003f2e:	86a6                	mv	a3,s1
    80003f30:	fc040613          	addi	a2,s0,-64
    80003f34:	4581                	li	a1,0
    80003f36:	854a                	mv	a0,s2
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	c44080e7          	jalr	-956(ra) # 80003b7c <writei>
    80003f40:	1541                	addi	a0,a0,-16
    80003f42:	00a03533          	snez	a0,a0
    80003f46:	40a00533          	neg	a0,a0
}
    80003f4a:	70e2                	ld	ra,56(sp)
    80003f4c:	7442                	ld	s0,48(sp)
    80003f4e:	74a2                	ld	s1,40(sp)
    80003f50:	7902                	ld	s2,32(sp)
    80003f52:	69e2                	ld	s3,24(sp)
    80003f54:	6a42                	ld	s4,16(sp)
    80003f56:	6121                	addi	sp,sp,64
    80003f58:	8082                	ret
    iput(ip);
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	a30080e7          	jalr	-1488(ra) # 8000398a <iput>
    return -1;
    80003f62:	557d                	li	a0,-1
    80003f64:	b7dd                	j	80003f4a <dirlink+0x86>
      panic("dirlink read");
    80003f66:	00004517          	auipc	a0,0x4
    80003f6a:	6c250513          	addi	a0,a0,1730 # 80008628 <syscalls+0x1d8>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5d6080e7          	jalr	1494(ra) # 80000544 <panic>

0000000080003f76 <namei>:

struct inode*
namei(char *path)
{
    80003f76:	1101                	addi	sp,sp,-32
    80003f78:	ec06                	sd	ra,24(sp)
    80003f7a:	e822                	sd	s0,16(sp)
    80003f7c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f7e:	fe040613          	addi	a2,s0,-32
    80003f82:	4581                	li	a1,0
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	de0080e7          	jalr	-544(ra) # 80003d64 <namex>
}
    80003f8c:	60e2                	ld	ra,24(sp)
    80003f8e:	6442                	ld	s0,16(sp)
    80003f90:	6105                	addi	sp,sp,32
    80003f92:	8082                	ret

0000000080003f94 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f94:	1141                	addi	sp,sp,-16
    80003f96:	e406                	sd	ra,8(sp)
    80003f98:	e022                	sd	s0,0(sp)
    80003f9a:	0800                	addi	s0,sp,16
    80003f9c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f9e:	4585                	li	a1,1
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	dc4080e7          	jalr	-572(ra) # 80003d64 <namex>
}
    80003fa8:	60a2                	ld	ra,8(sp)
    80003faa:	6402                	ld	s0,0(sp)
    80003fac:	0141                	addi	sp,sp,16
    80003fae:	8082                	ret

0000000080003fb0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb0:	1101                	addi	sp,sp,-32
    80003fb2:	ec06                	sd	ra,24(sp)
    80003fb4:	e822                	sd	s0,16(sp)
    80003fb6:	e426                	sd	s1,8(sp)
    80003fb8:	e04a                	sd	s2,0(sp)
    80003fba:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fbc:	0001d917          	auipc	s2,0x1d
    80003fc0:	d7490913          	addi	s2,s2,-652 # 80020d30 <log>
    80003fc4:	01892583          	lw	a1,24(s2)
    80003fc8:	02892503          	lw	a0,40(s2)
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	fea080e7          	jalr	-22(ra) # 80002fb6 <bread>
    80003fd4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd6:	02c92683          	lw	a3,44(s2)
    80003fda:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fdc:	02d05763          	blez	a3,8000400a <write_head+0x5a>
    80003fe0:	0001d797          	auipc	a5,0x1d
    80003fe4:	d8078793          	addi	a5,a5,-640 # 80020d60 <log+0x30>
    80003fe8:	05c50713          	addi	a4,a0,92
    80003fec:	36fd                	addiw	a3,a3,-1
    80003fee:	1682                	slli	a3,a3,0x20
    80003ff0:	9281                	srli	a3,a3,0x20
    80003ff2:	068a                	slli	a3,a3,0x2
    80003ff4:	0001d617          	auipc	a2,0x1d
    80003ff8:	d7060613          	addi	a2,a2,-656 # 80020d64 <log+0x34>
    80003ffc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ffe:	4390                	lw	a2,0(a5)
    80004000:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004002:	0791                	addi	a5,a5,4
    80004004:	0711                	addi	a4,a4,4
    80004006:	fed79ce3          	bne	a5,a3,80003ffe <write_head+0x4e>
  }
  bwrite(buf);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	09c080e7          	jalr	156(ra) # 800030a8 <bwrite>
  brelse(buf);
    80004014:	8526                	mv	a0,s1
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	0d0080e7          	jalr	208(ra) # 800030e6 <brelse>
}
    8000401e:	60e2                	ld	ra,24(sp)
    80004020:	6442                	ld	s0,16(sp)
    80004022:	64a2                	ld	s1,8(sp)
    80004024:	6902                	ld	s2,0(sp)
    80004026:	6105                	addi	sp,sp,32
    80004028:	8082                	ret

000000008000402a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402a:	0001d797          	auipc	a5,0x1d
    8000402e:	d327a783          	lw	a5,-718(a5) # 80020d5c <log+0x2c>
    80004032:	0af05d63          	blez	a5,800040ec <install_trans+0xc2>
{
    80004036:	7139                	addi	sp,sp,-64
    80004038:	fc06                	sd	ra,56(sp)
    8000403a:	f822                	sd	s0,48(sp)
    8000403c:	f426                	sd	s1,40(sp)
    8000403e:	f04a                	sd	s2,32(sp)
    80004040:	ec4e                	sd	s3,24(sp)
    80004042:	e852                	sd	s4,16(sp)
    80004044:	e456                	sd	s5,8(sp)
    80004046:	e05a                	sd	s6,0(sp)
    80004048:	0080                	addi	s0,sp,64
    8000404a:	8b2a                	mv	s6,a0
    8000404c:	0001da97          	auipc	s5,0x1d
    80004050:	d14a8a93          	addi	s5,s5,-748 # 80020d60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004056:	0001d997          	auipc	s3,0x1d
    8000405a:	cda98993          	addi	s3,s3,-806 # 80020d30 <log>
    8000405e:	a035                	j	8000408a <install_trans+0x60>
      bunpin(dbuf);
    80004060:	8526                	mv	a0,s1
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	15e080e7          	jalr	350(ra) # 800031c0 <bunpin>
    brelse(lbuf);
    8000406a:	854a                	mv	a0,s2
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	07a080e7          	jalr	122(ra) # 800030e6 <brelse>
    brelse(dbuf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	070080e7          	jalr	112(ra) # 800030e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407e:	2a05                	addiw	s4,s4,1
    80004080:	0a91                	addi	s5,s5,4
    80004082:	02c9a783          	lw	a5,44(s3)
    80004086:	04fa5963          	bge	s4,a5,800040d8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000408a:	0189a583          	lw	a1,24(s3)
    8000408e:	014585bb          	addw	a1,a1,s4
    80004092:	2585                	addiw	a1,a1,1
    80004094:	0289a503          	lw	a0,40(s3)
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	f1e080e7          	jalr	-226(ra) # 80002fb6 <bread>
    800040a0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040a2:	000aa583          	lw	a1,0(s5)
    800040a6:	0289a503          	lw	a0,40(s3)
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	f0c080e7          	jalr	-244(ra) # 80002fb6 <bread>
    800040b2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b4:	40000613          	li	a2,1024
    800040b8:	05890593          	addi	a1,s2,88
    800040bc:	05850513          	addi	a0,a0,88
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	cce080e7          	jalr	-818(ra) # 80000d8e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040c8:	8526                	mv	a0,s1
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	fde080e7          	jalr	-34(ra) # 800030a8 <bwrite>
    if(recovering == 0)
    800040d2:	f80b1ce3          	bnez	s6,8000406a <install_trans+0x40>
    800040d6:	b769                	j	80004060 <install_trans+0x36>
}
    800040d8:	70e2                	ld	ra,56(sp)
    800040da:	7442                	ld	s0,48(sp)
    800040dc:	74a2                	ld	s1,40(sp)
    800040de:	7902                	ld	s2,32(sp)
    800040e0:	69e2                	ld	s3,24(sp)
    800040e2:	6a42                	ld	s4,16(sp)
    800040e4:	6aa2                	ld	s5,8(sp)
    800040e6:	6b02                	ld	s6,0(sp)
    800040e8:	6121                	addi	sp,sp,64
    800040ea:	8082                	ret
    800040ec:	8082                	ret

00000000800040ee <initlog>:
{
    800040ee:	7179                	addi	sp,sp,-48
    800040f0:	f406                	sd	ra,40(sp)
    800040f2:	f022                	sd	s0,32(sp)
    800040f4:	ec26                	sd	s1,24(sp)
    800040f6:	e84a                	sd	s2,16(sp)
    800040f8:	e44e                	sd	s3,8(sp)
    800040fa:	1800                	addi	s0,sp,48
    800040fc:	892a                	mv	s2,a0
    800040fe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004100:	0001d497          	auipc	s1,0x1d
    80004104:	c3048493          	addi	s1,s1,-976 # 80020d30 <log>
    80004108:	00004597          	auipc	a1,0x4
    8000410c:	53058593          	addi	a1,a1,1328 # 80008638 <syscalls+0x1e8>
    80004110:	8526                	mv	a0,s1
    80004112:	ffffd097          	auipc	ra,0xffffd
    80004116:	a90080e7          	jalr	-1392(ra) # 80000ba2 <initlock>
  log.start = sb->logstart;
    8000411a:	0149a583          	lw	a1,20(s3)
    8000411e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004120:	0109a783          	lw	a5,16(s3)
    80004124:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004126:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000412a:	854a                	mv	a0,s2
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	e8a080e7          	jalr	-374(ra) # 80002fb6 <bread>
  log.lh.n = lh->n;
    80004134:	4d3c                	lw	a5,88(a0)
    80004136:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004138:	02f05563          	blez	a5,80004162 <initlog+0x74>
    8000413c:	05c50713          	addi	a4,a0,92
    80004140:	0001d697          	auipc	a3,0x1d
    80004144:	c2068693          	addi	a3,a3,-992 # 80020d60 <log+0x30>
    80004148:	37fd                	addiw	a5,a5,-1
    8000414a:	1782                	slli	a5,a5,0x20
    8000414c:	9381                	srli	a5,a5,0x20
    8000414e:	078a                	slli	a5,a5,0x2
    80004150:	06050613          	addi	a2,a0,96
    80004154:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004156:	4310                	lw	a2,0(a4)
    80004158:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000415a:	0711                	addi	a4,a4,4
    8000415c:	0691                	addi	a3,a3,4
    8000415e:	fef71ce3          	bne	a4,a5,80004156 <initlog+0x68>
  brelse(buf);
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	f84080e7          	jalr	-124(ra) # 800030e6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000416a:	4505                	li	a0,1
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	ebe080e7          	jalr	-322(ra) # 8000402a <install_trans>
  log.lh.n = 0;
    80004174:	0001d797          	auipc	a5,0x1d
    80004178:	be07a423          	sw	zero,-1048(a5) # 80020d5c <log+0x2c>
  write_head(); // clear the log
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	e34080e7          	jalr	-460(ra) # 80003fb0 <write_head>
}
    80004184:	70a2                	ld	ra,40(sp)
    80004186:	7402                	ld	s0,32(sp)
    80004188:	64e2                	ld	s1,24(sp)
    8000418a:	6942                	ld	s2,16(sp)
    8000418c:	69a2                	ld	s3,8(sp)
    8000418e:	6145                	addi	sp,sp,48
    80004190:	8082                	ret

0000000080004192 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004192:	1101                	addi	sp,sp,-32
    80004194:	ec06                	sd	ra,24(sp)
    80004196:	e822                	sd	s0,16(sp)
    80004198:	e426                	sd	s1,8(sp)
    8000419a:	e04a                	sd	s2,0(sp)
    8000419c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000419e:	0001d517          	auipc	a0,0x1d
    800041a2:	b9250513          	addi	a0,a0,-1134 # 80020d30 <log>
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	a8c080e7          	jalr	-1396(ra) # 80000c32 <acquire>
  while(1){
    if(log.committing){
    800041ae:	0001d497          	auipc	s1,0x1d
    800041b2:	b8248493          	addi	s1,s1,-1150 # 80020d30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b6:	4979                	li	s2,30
    800041b8:	a039                	j	800041c6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ba:	85a6                	mv	a1,s1
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	ef8080e7          	jalr	-264(ra) # 800020b6 <sleep>
    if(log.committing){
    800041c6:	50dc                	lw	a5,36(s1)
    800041c8:	fbed                	bnez	a5,800041ba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ca:	509c                	lw	a5,32(s1)
    800041cc:	0017871b          	addiw	a4,a5,1
    800041d0:	0007069b          	sext.w	a3,a4
    800041d4:	0027179b          	slliw	a5,a4,0x2
    800041d8:	9fb9                	addw	a5,a5,a4
    800041da:	0017979b          	slliw	a5,a5,0x1
    800041de:	54d8                	lw	a4,44(s1)
    800041e0:	9fb9                	addw	a5,a5,a4
    800041e2:	00f95963          	bge	s2,a5,800041f4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041e6:	85a6                	mv	a1,s1
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffe097          	auipc	ra,0xffffe
    800041ee:	ecc080e7          	jalr	-308(ra) # 800020b6 <sleep>
    800041f2:	bfd1                	j	800041c6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041f4:	0001d517          	auipc	a0,0x1d
    800041f8:	b3c50513          	addi	a0,a0,-1220 # 80020d30 <log>
    800041fc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041fe:	ffffd097          	auipc	ra,0xffffd
    80004202:	ae8080e7          	jalr	-1304(ra) # 80000ce6 <release>
      break;
    }
  }
}
    80004206:	60e2                	ld	ra,24(sp)
    80004208:	6442                	ld	s0,16(sp)
    8000420a:	64a2                	ld	s1,8(sp)
    8000420c:	6902                	ld	s2,0(sp)
    8000420e:	6105                	addi	sp,sp,32
    80004210:	8082                	ret

0000000080004212 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004212:	7139                	addi	sp,sp,-64
    80004214:	fc06                	sd	ra,56(sp)
    80004216:	f822                	sd	s0,48(sp)
    80004218:	f426                	sd	s1,40(sp)
    8000421a:	f04a                	sd	s2,32(sp)
    8000421c:	ec4e                	sd	s3,24(sp)
    8000421e:	e852                	sd	s4,16(sp)
    80004220:	e456                	sd	s5,8(sp)
    80004222:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004224:	0001d497          	auipc	s1,0x1d
    80004228:	b0c48493          	addi	s1,s1,-1268 # 80020d30 <log>
    8000422c:	8526                	mv	a0,s1
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	a04080e7          	jalr	-1532(ra) # 80000c32 <acquire>
  log.outstanding -= 1;
    80004236:	509c                	lw	a5,32(s1)
    80004238:	37fd                	addiw	a5,a5,-1
    8000423a:	0007891b          	sext.w	s2,a5
    8000423e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004240:	50dc                	lw	a5,36(s1)
    80004242:	efb9                	bnez	a5,800042a0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004244:	06091663          	bnez	s2,800042b0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004248:	0001d497          	auipc	s1,0x1d
    8000424c:	ae848493          	addi	s1,s1,-1304 # 80020d30 <log>
    80004250:	4785                	li	a5,1
    80004252:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004254:	8526                	mv	a0,s1
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	a90080e7          	jalr	-1392(ra) # 80000ce6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000425e:	54dc                	lw	a5,44(s1)
    80004260:	06f04763          	bgtz	a5,800042ce <end_op+0xbc>
    acquire(&log.lock);
    80004264:	0001d497          	auipc	s1,0x1d
    80004268:	acc48493          	addi	s1,s1,-1332 # 80020d30 <log>
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	9c4080e7          	jalr	-1596(ra) # 80000c32 <acquire>
    log.committing = 0;
    80004276:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000427a:	8526                	mv	a0,s1
    8000427c:	ffffe097          	auipc	ra,0xffffe
    80004280:	e9e080e7          	jalr	-354(ra) # 8000211a <wakeup>
    release(&log.lock);
    80004284:	8526                	mv	a0,s1
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	a60080e7          	jalr	-1440(ra) # 80000ce6 <release>
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6aa2                	ld	s5,8(sp)
    8000429c:	6121                	addi	sp,sp,64
    8000429e:	8082                	ret
    panic("log.committing");
    800042a0:	00004517          	auipc	a0,0x4
    800042a4:	3a050513          	addi	a0,a0,928 # 80008640 <syscalls+0x1f0>
    800042a8:	ffffc097          	auipc	ra,0xffffc
    800042ac:	29c080e7          	jalr	668(ra) # 80000544 <panic>
    wakeup(&log);
    800042b0:	0001d497          	auipc	s1,0x1d
    800042b4:	a8048493          	addi	s1,s1,-1408 # 80020d30 <log>
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffe097          	auipc	ra,0xffffe
    800042be:	e60080e7          	jalr	-416(ra) # 8000211a <wakeup>
  release(&log.lock);
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a22080e7          	jalr	-1502(ra) # 80000ce6 <release>
  if(do_commit){
    800042cc:	b7c9                	j	8000428e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ce:	0001da97          	auipc	s5,0x1d
    800042d2:	a92a8a93          	addi	s5,s5,-1390 # 80020d60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042d6:	0001da17          	auipc	s4,0x1d
    800042da:	a5aa0a13          	addi	s4,s4,-1446 # 80020d30 <log>
    800042de:	018a2583          	lw	a1,24(s4)
    800042e2:	012585bb          	addw	a1,a1,s2
    800042e6:	2585                	addiw	a1,a1,1
    800042e8:	028a2503          	lw	a0,40(s4)
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	cca080e7          	jalr	-822(ra) # 80002fb6 <bread>
    800042f4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042f6:	000aa583          	lw	a1,0(s5)
    800042fa:	028a2503          	lw	a0,40(s4)
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	cb8080e7          	jalr	-840(ra) # 80002fb6 <bread>
    80004306:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004308:	40000613          	li	a2,1024
    8000430c:	05850593          	addi	a1,a0,88
    80004310:	05848513          	addi	a0,s1,88
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	a7a080e7          	jalr	-1414(ra) # 80000d8e <memmove>
    bwrite(to);  // write the log
    8000431c:	8526                	mv	a0,s1
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	d8a080e7          	jalr	-630(ra) # 800030a8 <bwrite>
    brelse(from);
    80004326:	854e                	mv	a0,s3
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	dbe080e7          	jalr	-578(ra) # 800030e6 <brelse>
    brelse(to);
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	db4080e7          	jalr	-588(ra) # 800030e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433a:	2905                	addiw	s2,s2,1
    8000433c:	0a91                	addi	s5,s5,4
    8000433e:	02ca2783          	lw	a5,44(s4)
    80004342:	f8f94ee3          	blt	s2,a5,800042de <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c6a080e7          	jalr	-918(ra) # 80003fb0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000434e:	4501                	li	a0,0
    80004350:	00000097          	auipc	ra,0x0
    80004354:	cda080e7          	jalr	-806(ra) # 8000402a <install_trans>
    log.lh.n = 0;
    80004358:	0001d797          	auipc	a5,0x1d
    8000435c:	a007a223          	sw	zero,-1532(a5) # 80020d5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004360:	00000097          	auipc	ra,0x0
    80004364:	c50080e7          	jalr	-944(ra) # 80003fb0 <write_head>
    80004368:	bdf5                	j	80004264 <end_op+0x52>

000000008000436a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000436a:	1101                	addi	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	addi	s0,sp,32
    80004376:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004378:	0001d917          	auipc	s2,0x1d
    8000437c:	9b890913          	addi	s2,s2,-1608 # 80020d30 <log>
    80004380:	854a                	mv	a0,s2
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	8b0080e7          	jalr	-1872(ra) # 80000c32 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000438a:	02c92603          	lw	a2,44(s2)
    8000438e:	47f5                	li	a5,29
    80004390:	06c7c563          	blt	a5,a2,800043fa <log_write+0x90>
    80004394:	0001d797          	auipc	a5,0x1d
    80004398:	9b87a783          	lw	a5,-1608(a5) # 80020d4c <log+0x1c>
    8000439c:	37fd                	addiw	a5,a5,-1
    8000439e:	04f65e63          	bge	a2,a5,800043fa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a2:	0001d797          	auipc	a5,0x1d
    800043a6:	9ae7a783          	lw	a5,-1618(a5) # 80020d50 <log+0x20>
    800043aa:	06f05063          	blez	a5,8000440a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043ae:	4781                	li	a5,0
    800043b0:	06c05563          	blez	a2,8000441a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b4:	44cc                	lw	a1,12(s1)
    800043b6:	0001d717          	auipc	a4,0x1d
    800043ba:	9aa70713          	addi	a4,a4,-1622 # 80020d60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043be:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c0:	4314                	lw	a3,0(a4)
    800043c2:	04b68c63          	beq	a3,a1,8000441a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	2785                	addiw	a5,a5,1
    800043c8:	0711                	addi	a4,a4,4
    800043ca:	fef61be3          	bne	a2,a5,800043c0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ce:	0621                	addi	a2,a2,8
    800043d0:	060a                	slli	a2,a2,0x2
    800043d2:	0001d797          	auipc	a5,0x1d
    800043d6:	95e78793          	addi	a5,a5,-1698 # 80020d30 <log>
    800043da:	963e                	add	a2,a2,a5
    800043dc:	44dc                	lw	a5,12(s1)
    800043de:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	da2080e7          	jalr	-606(ra) # 80003184 <bpin>
    log.lh.n++;
    800043ea:	0001d717          	auipc	a4,0x1d
    800043ee:	94670713          	addi	a4,a4,-1722 # 80020d30 <log>
    800043f2:	575c                	lw	a5,44(a4)
    800043f4:	2785                	addiw	a5,a5,1
    800043f6:	d75c                	sw	a5,44(a4)
    800043f8:	a835                	j	80004434 <log_write+0xca>
    panic("too big a transaction");
    800043fa:	00004517          	auipc	a0,0x4
    800043fe:	25650513          	addi	a0,a0,598 # 80008650 <syscalls+0x200>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	142080e7          	jalr	322(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000440a:	00004517          	auipc	a0,0x4
    8000440e:	25e50513          	addi	a0,a0,606 # 80008668 <syscalls+0x218>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	132080e7          	jalr	306(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000441a:	00878713          	addi	a4,a5,8
    8000441e:	00271693          	slli	a3,a4,0x2
    80004422:	0001d717          	auipc	a4,0x1d
    80004426:	90e70713          	addi	a4,a4,-1778 # 80020d30 <log>
    8000442a:	9736                	add	a4,a4,a3
    8000442c:	44d4                	lw	a3,12(s1)
    8000442e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004430:	faf608e3          	beq	a2,a5,800043e0 <log_write+0x76>
  }
  release(&log.lock);
    80004434:	0001d517          	auipc	a0,0x1d
    80004438:	8fc50513          	addi	a0,a0,-1796 # 80020d30 <log>
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	8aa080e7          	jalr	-1878(ra) # 80000ce6 <release>
}
    80004444:	60e2                	ld	ra,24(sp)
    80004446:	6442                	ld	s0,16(sp)
    80004448:	64a2                	ld	s1,8(sp)
    8000444a:	6902                	ld	s2,0(sp)
    8000444c:	6105                	addi	sp,sp,32
    8000444e:	8082                	ret

0000000080004450 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004450:	1101                	addi	sp,sp,-32
    80004452:	ec06                	sd	ra,24(sp)
    80004454:	e822                	sd	s0,16(sp)
    80004456:	e426                	sd	s1,8(sp)
    80004458:	e04a                	sd	s2,0(sp)
    8000445a:	1000                	addi	s0,sp,32
    8000445c:	84aa                	mv	s1,a0
    8000445e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004460:	00004597          	auipc	a1,0x4
    80004464:	22858593          	addi	a1,a1,552 # 80008688 <syscalls+0x238>
    80004468:	0521                	addi	a0,a0,8
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	738080e7          	jalr	1848(ra) # 80000ba2 <initlock>
  lk->name = name;
    80004472:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004476:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000447a:	0204a423          	sw	zero,40(s1)
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
    80004496:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004498:	00850913          	addi	s2,a0,8
    8000449c:	854a                	mv	a0,s2
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	794080e7          	jalr	1940(ra) # 80000c32 <acquire>
  while (lk->locked) {
    800044a6:	409c                	lw	a5,0(s1)
    800044a8:	cb89                	beqz	a5,800044ba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044aa:	85ca                	mv	a1,s2
    800044ac:	8526                	mv	a0,s1
    800044ae:	ffffe097          	auipc	ra,0xffffe
    800044b2:	c08080e7          	jalr	-1016(ra) # 800020b6 <sleep>
  while (lk->locked) {
    800044b6:	409c                	lw	a5,0(s1)
    800044b8:	fbed                	bnez	a5,800044aa <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ba:	4785                	li	a5,1
    800044bc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	550080e7          	jalr	1360(ra) # 80001a0e <myproc>
    800044c6:	591c                	lw	a5,48(a0)
    800044c8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	81a080e7          	jalr	-2022(ra) # 80000ce6 <release>
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044e0:	1101                	addi	sp,sp,-32
    800044e2:	ec06                	sd	ra,24(sp)
    800044e4:	e822                	sd	s0,16(sp)
    800044e6:	e426                	sd	s1,8(sp)
    800044e8:	e04a                	sd	s2,0(sp)
    800044ea:	1000                	addi	s0,sp,32
    800044ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ee:	00850913          	addi	s2,a0,8
    800044f2:	854a                	mv	a0,s2
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	73e080e7          	jalr	1854(ra) # 80000c32 <acquire>
  lk->locked = 0;
    800044fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004500:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004504:	8526                	mv	a0,s1
    80004506:	ffffe097          	auipc	ra,0xffffe
    8000450a:	c14080e7          	jalr	-1004(ra) # 8000211a <wakeup>
  release(&lk->lk);
    8000450e:	854a                	mv	a0,s2
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	7d6080e7          	jalr	2006(ra) # 80000ce6 <release>
}
    80004518:	60e2                	ld	ra,24(sp)
    8000451a:	6442                	ld	s0,16(sp)
    8000451c:	64a2                	ld	s1,8(sp)
    8000451e:	6902                	ld	s2,0(sp)
    80004520:	6105                	addi	sp,sp,32
    80004522:	8082                	ret

0000000080004524 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004524:	7179                	addi	sp,sp,-48
    80004526:	f406                	sd	ra,40(sp)
    80004528:	f022                	sd	s0,32(sp)
    8000452a:	ec26                	sd	s1,24(sp)
    8000452c:	e84a                	sd	s2,16(sp)
    8000452e:	e44e                	sd	s3,8(sp)
    80004530:	1800                	addi	s0,sp,48
    80004532:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004534:	00850913          	addi	s2,a0,8
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	6f8080e7          	jalr	1784(ra) # 80000c32 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004542:	409c                	lw	a5,0(s1)
    80004544:	ef99                	bnez	a5,80004562 <holdingsleep+0x3e>
    80004546:	4481                	li	s1,0
  release(&lk->lk);
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	79c080e7          	jalr	1948(ra) # 80000ce6 <release>
  return r;
}
    80004552:	8526                	mv	a0,s1
    80004554:	70a2                	ld	ra,40(sp)
    80004556:	7402                	ld	s0,32(sp)
    80004558:	64e2                	ld	s1,24(sp)
    8000455a:	6942                	ld	s2,16(sp)
    8000455c:	69a2                	ld	s3,8(sp)
    8000455e:	6145                	addi	sp,sp,48
    80004560:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004562:	0284a983          	lw	s3,40(s1)
    80004566:	ffffd097          	auipc	ra,0xffffd
    8000456a:	4a8080e7          	jalr	1192(ra) # 80001a0e <myproc>
    8000456e:	5904                	lw	s1,48(a0)
    80004570:	413484b3          	sub	s1,s1,s3
    80004574:	0014b493          	seqz	s1,s1
    80004578:	bfc1                	j	80004548 <holdingsleep+0x24>

000000008000457a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000457a:	1141                	addi	sp,sp,-16
    8000457c:	e406                	sd	ra,8(sp)
    8000457e:	e022                	sd	s0,0(sp)
    80004580:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004582:	00004597          	auipc	a1,0x4
    80004586:	11658593          	addi	a1,a1,278 # 80008698 <syscalls+0x248>
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	8ee50513          	addi	a0,a0,-1810 # 80020e78 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	610080e7          	jalr	1552(ra) # 80000ba2 <initlock>
}
    8000459a:	60a2                	ld	ra,8(sp)
    8000459c:	6402                	ld	s0,0(sp)
    8000459e:	0141                	addi	sp,sp,16
    800045a0:	8082                	ret

00000000800045a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	8cc50513          	addi	a0,a0,-1844 # 80020e78 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	67e080e7          	jalr	1662(ra) # 80000c32 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045bc:	0001d497          	auipc	s1,0x1d
    800045c0:	8d448493          	addi	s1,s1,-1836 # 80020e90 <ftable+0x18>
    800045c4:	0001e717          	auipc	a4,0x1e
    800045c8:	86c70713          	addi	a4,a4,-1940 # 80021e30 <disk>
    if(f->ref == 0){
    800045cc:	40dc                	lw	a5,4(s1)
    800045ce:	cf99                	beqz	a5,800045ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d0:	02848493          	addi	s1,s1,40
    800045d4:	fee49ce3          	bne	s1,a4,800045cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	8a050513          	addi	a0,a0,-1888 # 80020e78 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	706080e7          	jalr	1798(ra) # 80000ce6 <release>
  return 0;
    800045e8:	4481                	li	s1,0
    800045ea:	a819                	j	80004600 <filealloc+0x5e>
      f->ref = 1;
    800045ec:	4785                	li	a5,1
    800045ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045f0:	0001d517          	auipc	a0,0x1d
    800045f4:	88850513          	addi	a0,a0,-1912 # 80020e78 <ftable>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	6ee080e7          	jalr	1774(ra) # 80000ce6 <release>
}
    80004600:	8526                	mv	a0,s1
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	64a2                	ld	s1,8(sp)
    80004608:	6105                	addi	sp,sp,32
    8000460a:	8082                	ret

000000008000460c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000460c:	1101                	addi	sp,sp,-32
    8000460e:	ec06                	sd	ra,24(sp)
    80004610:	e822                	sd	s0,16(sp)
    80004612:	e426                	sd	s1,8(sp)
    80004614:	1000                	addi	s0,sp,32
    80004616:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	86050513          	addi	a0,a0,-1952 # 80020e78 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	612080e7          	jalr	1554(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    80004628:	40dc                	lw	a5,4(s1)
    8000462a:	02f05263          	blez	a5,8000464e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462e:	2785                	addiw	a5,a5,1
    80004630:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	84650513          	addi	a0,a0,-1978 # 80020e78 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	6ac080e7          	jalr	1708(ra) # 80000ce6 <release>
  return f;
}
    80004642:	8526                	mv	a0,s1
    80004644:	60e2                	ld	ra,24(sp)
    80004646:	6442                	ld	s0,16(sp)
    80004648:	64a2                	ld	s1,8(sp)
    8000464a:	6105                	addi	sp,sp,32
    8000464c:	8082                	ret
    panic("filedup");
    8000464e:	00004517          	auipc	a0,0x4
    80004652:	05250513          	addi	a0,a0,82 # 800086a0 <syscalls+0x250>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	eee080e7          	jalr	-274(ra) # 80000544 <panic>

000000008000465e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465e:	7139                	addi	sp,sp,-64
    80004660:	fc06                	sd	ra,56(sp)
    80004662:	f822                	sd	s0,48(sp)
    80004664:	f426                	sd	s1,40(sp)
    80004666:	f04a                	sd	s2,32(sp)
    80004668:	ec4e                	sd	s3,24(sp)
    8000466a:	e852                	sd	s4,16(sp)
    8000466c:	e456                	sd	s5,8(sp)
    8000466e:	0080                	addi	s0,sp,64
    80004670:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	80650513          	addi	a0,a0,-2042 # 80020e78 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	5b8080e7          	jalr	1464(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    80004682:	40dc                	lw	a5,4(s1)
    80004684:	06f05163          	blez	a5,800046e6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004688:	37fd                	addiw	a5,a5,-1
    8000468a:	0007871b          	sext.w	a4,a5
    8000468e:	c0dc                	sw	a5,4(s1)
    80004690:	06e04363          	bgtz	a4,800046f6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004694:	0004a903          	lw	s2,0(s1)
    80004698:	0094ca83          	lbu	s5,9(s1)
    8000469c:	0104ba03          	ld	s4,16(s1)
    800046a0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046ac:	0001c517          	auipc	a0,0x1c
    800046b0:	7cc50513          	addi	a0,a0,1996 # 80020e78 <ftable>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	632080e7          	jalr	1586(ra) # 80000ce6 <release>

  if(ff.type == FD_PIPE){
    800046bc:	4785                	li	a5,1
    800046be:	04f90d63          	beq	s2,a5,80004718 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046c2:	3979                	addiw	s2,s2,-2
    800046c4:	4785                	li	a5,1
    800046c6:	0527e063          	bltu	a5,s2,80004706 <fileclose+0xa8>
    begin_op();
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	ac8080e7          	jalr	-1336(ra) # 80004192 <begin_op>
    iput(ff.ip);
    800046d2:	854e                	mv	a0,s3
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	2b6080e7          	jalr	694(ra) # 8000398a <iput>
    end_op();
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	b36080e7          	jalr	-1226(ra) # 80004212 <end_op>
    800046e4:	a00d                	j	80004706 <fileclose+0xa8>
    panic("fileclose");
    800046e6:	00004517          	auipc	a0,0x4
    800046ea:	fc250513          	addi	a0,a0,-62 # 800086a8 <syscalls+0x258>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	e56080e7          	jalr	-426(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046f6:	0001c517          	auipc	a0,0x1c
    800046fa:	78250513          	addi	a0,a0,1922 # 80020e78 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	5e8080e7          	jalr	1512(ra) # 80000ce6 <release>
  }
}
    80004706:	70e2                	ld	ra,56(sp)
    80004708:	7442                	ld	s0,48(sp)
    8000470a:	74a2                	ld	s1,40(sp)
    8000470c:	7902                	ld	s2,32(sp)
    8000470e:	69e2                	ld	s3,24(sp)
    80004710:	6a42                	ld	s4,16(sp)
    80004712:	6aa2                	ld	s5,8(sp)
    80004714:	6121                	addi	sp,sp,64
    80004716:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004718:	85d6                	mv	a1,s5
    8000471a:	8552                	mv	a0,s4
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	34c080e7          	jalr	844(ra) # 80004a68 <pipeclose>
    80004724:	b7cd                	j	80004706 <fileclose+0xa8>

0000000080004726 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004726:	715d                	addi	sp,sp,-80
    80004728:	e486                	sd	ra,72(sp)
    8000472a:	e0a2                	sd	s0,64(sp)
    8000472c:	fc26                	sd	s1,56(sp)
    8000472e:	f84a                	sd	s2,48(sp)
    80004730:	f44e                	sd	s3,40(sp)
    80004732:	0880                	addi	s0,sp,80
    80004734:	84aa                	mv	s1,a0
    80004736:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004738:	ffffd097          	auipc	ra,0xffffd
    8000473c:	2d6080e7          	jalr	726(ra) # 80001a0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004740:	409c                	lw	a5,0(s1)
    80004742:	37f9                	addiw	a5,a5,-2
    80004744:	4705                	li	a4,1
    80004746:	04f76763          	bltu	a4,a5,80004794 <filestat+0x6e>
    8000474a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	082080e7          	jalr	130(ra) # 800037d0 <ilock>
    stati(f->ip, &st);
    80004756:	fb840593          	addi	a1,s0,-72
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	2fe080e7          	jalr	766(ra) # 80003a5a <stati>
    iunlock(f->ip);
    80004764:	6c88                	ld	a0,24(s1)
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	12c080e7          	jalr	300(ra) # 80003892 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476e:	46e1                	li	a3,24
    80004770:	fb840613          	addi	a2,s0,-72
    80004774:	85ce                	mv	a1,s3
    80004776:	05093503          	ld	a0,80(s2)
    8000477a:	ffffd097          	auipc	ra,0xffffd
    8000477e:	f52080e7          	jalr	-174(ra) # 800016cc <copyout>
    80004782:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004786:	60a6                	ld	ra,72(sp)
    80004788:	6406                	ld	s0,64(sp)
    8000478a:	74e2                	ld	s1,56(sp)
    8000478c:	7942                	ld	s2,48(sp)
    8000478e:	79a2                	ld	s3,40(sp)
    80004790:	6161                	addi	sp,sp,80
    80004792:	8082                	ret
  return -1;
    80004794:	557d                	li	a0,-1
    80004796:	bfc5                	j	80004786 <filestat+0x60>

0000000080004798 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004798:	7179                	addi	sp,sp,-48
    8000479a:	f406                	sd	ra,40(sp)
    8000479c:	f022                	sd	s0,32(sp)
    8000479e:	ec26                	sd	s1,24(sp)
    800047a0:	e84a                	sd	s2,16(sp)
    800047a2:	e44e                	sd	s3,8(sp)
    800047a4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a6:	00854783          	lbu	a5,8(a0)
    800047aa:	c3d5                	beqz	a5,8000484e <fileread+0xb6>
    800047ac:	84aa                	mv	s1,a0
    800047ae:	89ae                	mv	s3,a1
    800047b0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b2:	411c                	lw	a5,0(a0)
    800047b4:	4705                	li	a4,1
    800047b6:	04e78963          	beq	a5,a4,80004808 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ba:	470d                	li	a4,3
    800047bc:	04e78d63          	beq	a5,a4,80004816 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c0:	4709                	li	a4,2
    800047c2:	06e79e63          	bne	a5,a4,8000483e <fileread+0xa6>
    ilock(f->ip);
    800047c6:	6d08                	ld	a0,24(a0)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	008080e7          	jalr	8(ra) # 800037d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047d0:	874a                	mv	a4,s2
    800047d2:	5094                	lw	a3,32(s1)
    800047d4:	864e                	mv	a2,s3
    800047d6:	4585                	li	a1,1
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	2aa080e7          	jalr	682(ra) # 80003a84 <readi>
    800047e2:	892a                	mv	s2,a0
    800047e4:	00a05563          	blez	a0,800047ee <fileread+0x56>
      f->off += r;
    800047e8:	509c                	lw	a5,32(s1)
    800047ea:	9fa9                	addw	a5,a5,a0
    800047ec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ee:	6c88                	ld	a0,24(s1)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	0a2080e7          	jalr	162(ra) # 80003892 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f8:	854a                	mv	a0,s2
    800047fa:	70a2                	ld	ra,40(sp)
    800047fc:	7402                	ld	s0,32(sp)
    800047fe:	64e2                	ld	s1,24(sp)
    80004800:	6942                	ld	s2,16(sp)
    80004802:	69a2                	ld	s3,8(sp)
    80004804:	6145                	addi	sp,sp,48
    80004806:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004808:	6908                	ld	a0,16(a0)
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	3ce080e7          	jalr	974(ra) # 80004bd8 <piperead>
    80004812:	892a                	mv	s2,a0
    80004814:	b7d5                	j	800047f8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004816:	02451783          	lh	a5,36(a0)
    8000481a:	03079693          	slli	a3,a5,0x30
    8000481e:	92c1                	srli	a3,a3,0x30
    80004820:	4725                	li	a4,9
    80004822:	02d76863          	bltu	a4,a3,80004852 <fileread+0xba>
    80004826:	0792                	slli	a5,a5,0x4
    80004828:	0001c717          	auipc	a4,0x1c
    8000482c:	5b070713          	addi	a4,a4,1456 # 80020dd8 <devsw>
    80004830:	97ba                	add	a5,a5,a4
    80004832:	639c                	ld	a5,0(a5)
    80004834:	c38d                	beqz	a5,80004856 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004836:	4505                	li	a0,1
    80004838:	9782                	jalr	a5
    8000483a:	892a                	mv	s2,a0
    8000483c:	bf75                	j	800047f8 <fileread+0x60>
    panic("fileread");
    8000483e:	00004517          	auipc	a0,0x4
    80004842:	e7a50513          	addi	a0,a0,-390 # 800086b8 <syscalls+0x268>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	cfe080e7          	jalr	-770(ra) # 80000544 <panic>
    return -1;
    8000484e:	597d                	li	s2,-1
    80004850:	b765                	j	800047f8 <fileread+0x60>
      return -1;
    80004852:	597d                	li	s2,-1
    80004854:	b755                	j	800047f8 <fileread+0x60>
    80004856:	597d                	li	s2,-1
    80004858:	b745                	j	800047f8 <fileread+0x60>

000000008000485a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000485a:	715d                	addi	sp,sp,-80
    8000485c:	e486                	sd	ra,72(sp)
    8000485e:	e0a2                	sd	s0,64(sp)
    80004860:	fc26                	sd	s1,56(sp)
    80004862:	f84a                	sd	s2,48(sp)
    80004864:	f44e                	sd	s3,40(sp)
    80004866:	f052                	sd	s4,32(sp)
    80004868:	ec56                	sd	s5,24(sp)
    8000486a:	e85a                	sd	s6,16(sp)
    8000486c:	e45e                	sd	s7,8(sp)
    8000486e:	e062                	sd	s8,0(sp)
    80004870:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004872:	00954783          	lbu	a5,9(a0)
    80004876:	10078663          	beqz	a5,80004982 <filewrite+0x128>
    8000487a:	892a                	mv	s2,a0
    8000487c:	8aae                	mv	s5,a1
    8000487e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004880:	411c                	lw	a5,0(a0)
    80004882:	4705                	li	a4,1
    80004884:	02e78263          	beq	a5,a4,800048a8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004888:	470d                	li	a4,3
    8000488a:	02e78663          	beq	a5,a4,800048b6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488e:	4709                	li	a4,2
    80004890:	0ee79163          	bne	a5,a4,80004972 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004894:	0ac05d63          	blez	a2,8000494e <filewrite+0xf4>
    int i = 0;
    80004898:	4981                	li	s3,0
    8000489a:	6b05                	lui	s6,0x1
    8000489c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048a0:	6b85                	lui	s7,0x1
    800048a2:	c00b8b9b          	addiw	s7,s7,-1024
    800048a6:	a861                	j	8000493e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048a8:	6908                	ld	a0,16(a0)
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	22e080e7          	jalr	558(ra) # 80004ad8 <pipewrite>
    800048b2:	8a2a                	mv	s4,a0
    800048b4:	a045                	j	80004954 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b6:	02451783          	lh	a5,36(a0)
    800048ba:	03079693          	slli	a3,a5,0x30
    800048be:	92c1                	srli	a3,a3,0x30
    800048c0:	4725                	li	a4,9
    800048c2:	0cd76263          	bltu	a4,a3,80004986 <filewrite+0x12c>
    800048c6:	0792                	slli	a5,a5,0x4
    800048c8:	0001c717          	auipc	a4,0x1c
    800048cc:	51070713          	addi	a4,a4,1296 # 80020dd8 <devsw>
    800048d0:	97ba                	add	a5,a5,a4
    800048d2:	679c                	ld	a5,8(a5)
    800048d4:	cbdd                	beqz	a5,8000498a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048d6:	4505                	li	a0,1
    800048d8:	9782                	jalr	a5
    800048da:	8a2a                	mv	s4,a0
    800048dc:	a8a5                	j	80004954 <filewrite+0xfa>
    800048de:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	8b0080e7          	jalr	-1872(ra) # 80004192 <begin_op>
      ilock(f->ip);
    800048ea:	01893503          	ld	a0,24(s2)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	ee2080e7          	jalr	-286(ra) # 800037d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f6:	8762                	mv	a4,s8
    800048f8:	02092683          	lw	a3,32(s2)
    800048fc:	01598633          	add	a2,s3,s5
    80004900:	4585                	li	a1,1
    80004902:	01893503          	ld	a0,24(s2)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	276080e7          	jalr	630(ra) # 80003b7c <writei>
    8000490e:	84aa                	mv	s1,a0
    80004910:	00a05763          	blez	a0,8000491e <filewrite+0xc4>
        f->off += r;
    80004914:	02092783          	lw	a5,32(s2)
    80004918:	9fa9                	addw	a5,a5,a0
    8000491a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000491e:	01893503          	ld	a0,24(s2)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	f70080e7          	jalr	-144(ra) # 80003892 <iunlock>
      end_op();
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	8e8080e7          	jalr	-1816(ra) # 80004212 <end_op>

      if(r != n1){
    80004932:	009c1f63          	bne	s8,s1,80004950 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004936:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000493a:	0149db63          	bge	s3,s4,80004950 <filewrite+0xf6>
      int n1 = n - i;
    8000493e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004942:	84be                	mv	s1,a5
    80004944:	2781                	sext.w	a5,a5
    80004946:	f8fb5ce3          	bge	s6,a5,800048de <filewrite+0x84>
    8000494a:	84de                	mv	s1,s7
    8000494c:	bf49                	j	800048de <filewrite+0x84>
    int i = 0;
    8000494e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004950:	013a1f63          	bne	s4,s3,8000496e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004954:	8552                	mv	a0,s4
    80004956:	60a6                	ld	ra,72(sp)
    80004958:	6406                	ld	s0,64(sp)
    8000495a:	74e2                	ld	s1,56(sp)
    8000495c:	7942                	ld	s2,48(sp)
    8000495e:	79a2                	ld	s3,40(sp)
    80004960:	7a02                	ld	s4,32(sp)
    80004962:	6ae2                	ld	s5,24(sp)
    80004964:	6b42                	ld	s6,16(sp)
    80004966:	6ba2                	ld	s7,8(sp)
    80004968:	6c02                	ld	s8,0(sp)
    8000496a:	6161                	addi	sp,sp,80
    8000496c:	8082                	ret
    ret = (i == n ? n : -1);
    8000496e:	5a7d                	li	s4,-1
    80004970:	b7d5                	j	80004954 <filewrite+0xfa>
    panic("filewrite");
    80004972:	00004517          	auipc	a0,0x4
    80004976:	d5650513          	addi	a0,a0,-682 # 800086c8 <syscalls+0x278>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	bca080e7          	jalr	-1078(ra) # 80000544 <panic>
    return -1;
    80004982:	5a7d                	li	s4,-1
    80004984:	bfc1                	j	80004954 <filewrite+0xfa>
      return -1;
    80004986:	5a7d                	li	s4,-1
    80004988:	b7f1                	j	80004954 <filewrite+0xfa>
    8000498a:	5a7d                	li	s4,-1
    8000498c:	b7e1                	j	80004954 <filewrite+0xfa>

000000008000498e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498e:	7179                	addi	sp,sp,-48
    80004990:	f406                	sd	ra,40(sp)
    80004992:	f022                	sd	s0,32(sp)
    80004994:	ec26                	sd	s1,24(sp)
    80004996:	e84a                	sd	s2,16(sp)
    80004998:	e44e                	sd	s3,8(sp)
    8000499a:	e052                	sd	s4,0(sp)
    8000499c:	1800                	addi	s0,sp,48
    8000499e:	84aa                	mv	s1,a0
    800049a0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049a2:	0005b023          	sd	zero,0(a1)
    800049a6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	bf8080e7          	jalr	-1032(ra) # 800045a2 <filealloc>
    800049b2:	e088                	sd	a0,0(s1)
    800049b4:	c551                	beqz	a0,80004a40 <pipealloc+0xb2>
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	bec080e7          	jalr	-1044(ra) # 800045a2 <filealloc>
    800049be:	00aa3023          	sd	a0,0(s4)
    800049c2:	c92d                	beqz	a0,80004a34 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	136080e7          	jalr	310(ra) # 80000afa <kalloc>
    800049cc:	892a                	mv	s2,a0
    800049ce:	c125                	beqz	a0,80004a2e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049d0:	4985                	li	s3,1
    800049d2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049da:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049de:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e2:	00004597          	auipc	a1,0x4
    800049e6:	cf658593          	addi	a1,a1,-778 # 800086d8 <syscalls+0x288>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	1b8080e7          	jalr	440(ra) # 80000ba2 <initlock>
  (*f0)->type = FD_PIPE;
    800049f2:	609c                	ld	a5,0(s1)
    800049f4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f8:	609c                	ld	a5,0(s1)
    800049fa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fe:	609c                	ld	a5,0(s1)
    80004a00:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a04:	609c                	ld	a5,0(s1)
    80004a06:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a0a:	000a3783          	ld	a5,0(s4)
    80004a0e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a12:	000a3783          	ld	a5,0(s4)
    80004a16:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a1a:	000a3783          	ld	a5,0(s4)
    80004a1e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a22:	000a3783          	ld	a5,0(s4)
    80004a26:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a2a:	4501                	li	a0,0
    80004a2c:	a025                	j	80004a54 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a2e:	6088                	ld	a0,0(s1)
    80004a30:	e501                	bnez	a0,80004a38 <pipealloc+0xaa>
    80004a32:	a039                	j	80004a40 <pipealloc+0xb2>
    80004a34:	6088                	ld	a0,0(s1)
    80004a36:	c51d                	beqz	a0,80004a64 <pipealloc+0xd6>
    fileclose(*f0);
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	c26080e7          	jalr	-986(ra) # 8000465e <fileclose>
  if(*f1)
    80004a40:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a44:	557d                	li	a0,-1
  if(*f1)
    80004a46:	c799                	beqz	a5,80004a54 <pipealloc+0xc6>
    fileclose(*f1);
    80004a48:	853e                	mv	a0,a5
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	c14080e7          	jalr	-1004(ra) # 8000465e <fileclose>
  return -1;
    80004a52:	557d                	li	a0,-1
}
    80004a54:	70a2                	ld	ra,40(sp)
    80004a56:	7402                	ld	s0,32(sp)
    80004a58:	64e2                	ld	s1,24(sp)
    80004a5a:	6942                	ld	s2,16(sp)
    80004a5c:	69a2                	ld	s3,8(sp)
    80004a5e:	6a02                	ld	s4,0(sp)
    80004a60:	6145                	addi	sp,sp,48
    80004a62:	8082                	ret
  return -1;
    80004a64:	557d                	li	a0,-1
    80004a66:	b7fd                	j	80004a54 <pipealloc+0xc6>

0000000080004a68 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a68:	1101                	addi	sp,sp,-32
    80004a6a:	ec06                	sd	ra,24(sp)
    80004a6c:	e822                	sd	s0,16(sp)
    80004a6e:	e426                	sd	s1,8(sp)
    80004a70:	e04a                	sd	s2,0(sp)
    80004a72:	1000                	addi	s0,sp,32
    80004a74:	84aa                	mv	s1,a0
    80004a76:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	1ba080e7          	jalr	442(ra) # 80000c32 <acquire>
  if(writable){
    80004a80:	02090d63          	beqz	s2,80004aba <pipeclose+0x52>
    pi->writeopen = 0;
    80004a84:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a88:	21848513          	addi	a0,s1,536
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	68e080e7          	jalr	1678(ra) # 8000211a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a94:	2204b783          	ld	a5,544(s1)
    80004a98:	eb95                	bnez	a5,80004acc <pipeclose+0x64>
    release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	24a080e7          	jalr	586(ra) # 80000ce6 <release>
    kfree((char*)pi);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	f58080e7          	jalr	-168(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004aae:	60e2                	ld	ra,24(sp)
    80004ab0:	6442                	ld	s0,16(sp)
    80004ab2:	64a2                	ld	s1,8(sp)
    80004ab4:	6902                	ld	s2,0(sp)
    80004ab6:	6105                	addi	sp,sp,32
    80004ab8:	8082                	ret
    pi->readopen = 0;
    80004aba:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004abe:	21c48513          	addi	a0,s1,540
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	658080e7          	jalr	1624(ra) # 8000211a <wakeup>
    80004aca:	b7e9                	j	80004a94 <pipeclose+0x2c>
    release(&pi->lock);
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	218080e7          	jalr	536(ra) # 80000ce6 <release>
}
    80004ad6:	bfe1                	j	80004aae <pipeclose+0x46>

0000000080004ad8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad8:	7159                	addi	sp,sp,-112
    80004ada:	f486                	sd	ra,104(sp)
    80004adc:	f0a2                	sd	s0,96(sp)
    80004ade:	eca6                	sd	s1,88(sp)
    80004ae0:	e8ca                	sd	s2,80(sp)
    80004ae2:	e4ce                	sd	s3,72(sp)
    80004ae4:	e0d2                	sd	s4,64(sp)
    80004ae6:	fc56                	sd	s5,56(sp)
    80004ae8:	f85a                	sd	s6,48(sp)
    80004aea:	f45e                	sd	s7,40(sp)
    80004aec:	f062                	sd	s8,32(sp)
    80004aee:	ec66                	sd	s9,24(sp)
    80004af0:	1880                	addi	s0,sp,112
    80004af2:	84aa                	mv	s1,a0
    80004af4:	8aae                	mv	s5,a1
    80004af6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	f16080e7          	jalr	-234(ra) # 80001a0e <myproc>
    80004b00:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b02:	8526                	mv	a0,s1
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	12e080e7          	jalr	302(ra) # 80000c32 <acquire>
  while(i < n){
    80004b0c:	0d405463          	blez	s4,80004bd4 <pipewrite+0xfc>
    80004b10:	8ba6                	mv	s7,s1
  int i = 0;
    80004b12:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b14:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b16:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b1a:	21c48c13          	addi	s8,s1,540
    80004b1e:	a08d                	j	80004b80 <pipewrite+0xa8>
      release(&pi->lock);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	1c4080e7          	jalr	452(ra) # 80000ce6 <release>
      return -1;
    80004b2a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b2c:	854a                	mv	a0,s2
    80004b2e:	70a6                	ld	ra,104(sp)
    80004b30:	7406                	ld	s0,96(sp)
    80004b32:	64e6                	ld	s1,88(sp)
    80004b34:	6946                	ld	s2,80(sp)
    80004b36:	69a6                	ld	s3,72(sp)
    80004b38:	6a06                	ld	s4,64(sp)
    80004b3a:	7ae2                	ld	s5,56(sp)
    80004b3c:	7b42                	ld	s6,48(sp)
    80004b3e:	7ba2                	ld	s7,40(sp)
    80004b40:	7c02                	ld	s8,32(sp)
    80004b42:	6ce2                	ld	s9,24(sp)
    80004b44:	6165                	addi	sp,sp,112
    80004b46:	8082                	ret
      wakeup(&pi->nread);
    80004b48:	8566                	mv	a0,s9
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	5d0080e7          	jalr	1488(ra) # 8000211a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b52:	85de                	mv	a1,s7
    80004b54:	8562                	mv	a0,s8
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	560080e7          	jalr	1376(ra) # 800020b6 <sleep>
    80004b5e:	a839                	j	80004b7c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b60:	21c4a783          	lw	a5,540(s1)
    80004b64:	0017871b          	addiw	a4,a5,1
    80004b68:	20e4ae23          	sw	a4,540(s1)
    80004b6c:	1ff7f793          	andi	a5,a5,511
    80004b70:	97a6                	add	a5,a5,s1
    80004b72:	f9f44703          	lbu	a4,-97(s0)
    80004b76:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b7a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b7c:	05495063          	bge	s2,s4,80004bbc <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b80:	2204a783          	lw	a5,544(s1)
    80004b84:	dfd1                	beqz	a5,80004b20 <pipewrite+0x48>
    80004b86:	854e                	mv	a0,s3
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	7d6080e7          	jalr	2006(ra) # 8000235e <killed>
    80004b90:	f941                	bnez	a0,80004b20 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b92:	2184a783          	lw	a5,536(s1)
    80004b96:	21c4a703          	lw	a4,540(s1)
    80004b9a:	2007879b          	addiw	a5,a5,512
    80004b9e:	faf705e3          	beq	a4,a5,80004b48 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba2:	4685                	li	a3,1
    80004ba4:	01590633          	add	a2,s2,s5
    80004ba8:	f9f40593          	addi	a1,s0,-97
    80004bac:	0509b503          	ld	a0,80(s3)
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	ba8080e7          	jalr	-1112(ra) # 80001758 <copyin>
    80004bb8:	fb6514e3          	bne	a0,s6,80004b60 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bbc:	21848513          	addi	a0,s1,536
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	55a080e7          	jalr	1370(ra) # 8000211a <wakeup>
  release(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	11c080e7          	jalr	284(ra) # 80000ce6 <release>
  return i;
    80004bd2:	bfa9                	j	80004b2c <pipewrite+0x54>
  int i = 0;
    80004bd4:	4901                	li	s2,0
    80004bd6:	b7dd                	j	80004bbc <pipewrite+0xe4>

0000000080004bd8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bd8:	715d                	addi	sp,sp,-80
    80004bda:	e486                	sd	ra,72(sp)
    80004bdc:	e0a2                	sd	s0,64(sp)
    80004bde:	fc26                	sd	s1,56(sp)
    80004be0:	f84a                	sd	s2,48(sp)
    80004be2:	f44e                	sd	s3,40(sp)
    80004be4:	f052                	sd	s4,32(sp)
    80004be6:	ec56                	sd	s5,24(sp)
    80004be8:	e85a                	sd	s6,16(sp)
    80004bea:	0880                	addi	s0,sp,80
    80004bec:	84aa                	mv	s1,a0
    80004bee:	892e                	mv	s2,a1
    80004bf0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	e1c080e7          	jalr	-484(ra) # 80001a0e <myproc>
    80004bfa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bfc:	8b26                	mv	s6,s1
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	032080e7          	jalr	50(ra) # 80000c32 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c08:	2184a703          	lw	a4,536(s1)
    80004c0c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c10:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c14:	02f71763          	bne	a4,a5,80004c42 <piperead+0x6a>
    80004c18:	2244a783          	lw	a5,548(s1)
    80004c1c:	c39d                	beqz	a5,80004c42 <piperead+0x6a>
    if(killed(pr)){
    80004c1e:	8552                	mv	a0,s4
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	73e080e7          	jalr	1854(ra) # 8000235e <killed>
    80004c28:	e941                	bnez	a0,80004cb8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2a:	85da                	mv	a1,s6
    80004c2c:	854e                	mv	a0,s3
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	488080e7          	jalr	1160(ra) # 800020b6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c36:	2184a703          	lw	a4,536(s1)
    80004c3a:	21c4a783          	lw	a5,540(s1)
    80004c3e:	fcf70de3          	beq	a4,a5,80004c18 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c42:	09505263          	blez	s5,80004cc6 <piperead+0xee>
    80004c46:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c48:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c4a:	2184a783          	lw	a5,536(s1)
    80004c4e:	21c4a703          	lw	a4,540(s1)
    80004c52:	02f70d63          	beq	a4,a5,80004c8c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c56:	0017871b          	addiw	a4,a5,1
    80004c5a:	20e4ac23          	sw	a4,536(s1)
    80004c5e:	1ff7f793          	andi	a5,a5,511
    80004c62:	97a6                	add	a5,a5,s1
    80004c64:	0187c783          	lbu	a5,24(a5)
    80004c68:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c6c:	4685                	li	a3,1
    80004c6e:	fbf40613          	addi	a2,s0,-65
    80004c72:	85ca                	mv	a1,s2
    80004c74:	050a3503          	ld	a0,80(s4)
    80004c78:	ffffd097          	auipc	ra,0xffffd
    80004c7c:	a54080e7          	jalr	-1452(ra) # 800016cc <copyout>
    80004c80:	01650663          	beq	a0,s6,80004c8c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c84:	2985                	addiw	s3,s3,1
    80004c86:	0905                	addi	s2,s2,1
    80004c88:	fd3a91e3          	bne	s5,s3,80004c4a <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c8c:	21c48513          	addi	a0,s1,540
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	48a080e7          	jalr	1162(ra) # 8000211a <wakeup>
  release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	04c080e7          	jalr	76(ra) # 80000ce6 <release>
  return i;
}
    80004ca2:	854e                	mv	a0,s3
    80004ca4:	60a6                	ld	ra,72(sp)
    80004ca6:	6406                	ld	s0,64(sp)
    80004ca8:	74e2                	ld	s1,56(sp)
    80004caa:	7942                	ld	s2,48(sp)
    80004cac:	79a2                	ld	s3,40(sp)
    80004cae:	7a02                	ld	s4,32(sp)
    80004cb0:	6ae2                	ld	s5,24(sp)
    80004cb2:	6b42                	ld	s6,16(sp)
    80004cb4:	6161                	addi	sp,sp,80
    80004cb6:	8082                	ret
      release(&pi->lock);
    80004cb8:	8526                	mv	a0,s1
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	02c080e7          	jalr	44(ra) # 80000ce6 <release>
      return -1;
    80004cc2:	59fd                	li	s3,-1
    80004cc4:	bff9                	j	80004ca2 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc6:	4981                	li	s3,0
    80004cc8:	b7d1                	j	80004c8c <piperead+0xb4>

0000000080004cca <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cca:	1141                	addi	sp,sp,-16
    80004ccc:	e422                	sd	s0,8(sp)
    80004cce:	0800                	addi	s0,sp,16
    80004cd0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cd2:	8905                	andi	a0,a0,1
    80004cd4:	c111                	beqz	a0,80004cd8 <flags2perm+0xe>
      perm = PTE_X;
    80004cd6:	4521                	li	a0,8
    if(flags & 0x2)
    80004cd8:	8b89                	andi	a5,a5,2
    80004cda:	c399                	beqz	a5,80004ce0 <flags2perm+0x16>
      perm |= PTE_W;
    80004cdc:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ce0:	6422                	ld	s0,8(sp)
    80004ce2:	0141                	addi	sp,sp,16
    80004ce4:	8082                	ret

0000000080004ce6 <exec>:

int
exec(char *path, char **argv)
{
    80004ce6:	df010113          	addi	sp,sp,-528
    80004cea:	20113423          	sd	ra,520(sp)
    80004cee:	20813023          	sd	s0,512(sp)
    80004cf2:	ffa6                	sd	s1,504(sp)
    80004cf4:	fbca                	sd	s2,496(sp)
    80004cf6:	f7ce                	sd	s3,488(sp)
    80004cf8:	f3d2                	sd	s4,480(sp)
    80004cfa:	efd6                	sd	s5,472(sp)
    80004cfc:	ebda                	sd	s6,464(sp)
    80004cfe:	e7de                	sd	s7,456(sp)
    80004d00:	e3e2                	sd	s8,448(sp)
    80004d02:	ff66                	sd	s9,440(sp)
    80004d04:	fb6a                	sd	s10,432(sp)
    80004d06:	f76e                	sd	s11,424(sp)
    80004d08:	0c00                	addi	s0,sp,528
    80004d0a:	84aa                	mv	s1,a0
    80004d0c:	dea43c23          	sd	a0,-520(s0)
    80004d10:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	cfa080e7          	jalr	-774(ra) # 80001a0e <myproc>
    80004d1c:	892a                	mv	s2,a0

  begin_op();
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	474080e7          	jalr	1140(ra) # 80004192 <begin_op>

  if((ip = namei(path)) == 0){
    80004d26:	8526                	mv	a0,s1
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	24e080e7          	jalr	590(ra) # 80003f76 <namei>
    80004d30:	c92d                	beqz	a0,80004da2 <exec+0xbc>
    80004d32:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	a9c080e7          	jalr	-1380(ra) # 800037d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d3c:	04000713          	li	a4,64
    80004d40:	4681                	li	a3,0
    80004d42:	e5040613          	addi	a2,s0,-432
    80004d46:	4581                	li	a1,0
    80004d48:	8526                	mv	a0,s1
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	d3a080e7          	jalr	-710(ra) # 80003a84 <readi>
    80004d52:	04000793          	li	a5,64
    80004d56:	00f51a63          	bne	a0,a5,80004d6a <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d5a:	e5042703          	lw	a4,-432(s0)
    80004d5e:	464c47b7          	lui	a5,0x464c4
    80004d62:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d66:	04f70463          	beq	a4,a5,80004dae <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	cc6080e7          	jalr	-826(ra) # 80003a32 <iunlockput>
    end_op();
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	49e080e7          	jalr	1182(ra) # 80004212 <end_op>
  }
  return -1;
    80004d7c:	557d                	li	a0,-1
}
    80004d7e:	20813083          	ld	ra,520(sp)
    80004d82:	20013403          	ld	s0,512(sp)
    80004d86:	74fe                	ld	s1,504(sp)
    80004d88:	795e                	ld	s2,496(sp)
    80004d8a:	79be                	ld	s3,488(sp)
    80004d8c:	7a1e                	ld	s4,480(sp)
    80004d8e:	6afe                	ld	s5,472(sp)
    80004d90:	6b5e                	ld	s6,464(sp)
    80004d92:	6bbe                	ld	s7,456(sp)
    80004d94:	6c1e                	ld	s8,448(sp)
    80004d96:	7cfa                	ld	s9,440(sp)
    80004d98:	7d5a                	ld	s10,432(sp)
    80004d9a:	7dba                	ld	s11,424(sp)
    80004d9c:	21010113          	addi	sp,sp,528
    80004da0:	8082                	ret
    end_op();
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	470080e7          	jalr	1136(ra) # 80004212 <end_op>
    return -1;
    80004daa:	557d                	li	a0,-1
    80004dac:	bfc9                	j	80004d7e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dae:	854a                	mv	a0,s2
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	d22080e7          	jalr	-734(ra) # 80001ad2 <proc_pagetable>
    80004db8:	8baa                	mv	s7,a0
    80004dba:	d945                	beqz	a0,80004d6a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dbc:	e7042983          	lw	s3,-400(s0)
    80004dc0:	e8845783          	lhu	a5,-376(s0)
    80004dc4:	c7ad                	beqz	a5,80004e2e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc6:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dca:	6c85                	lui	s9,0x1
    80004dcc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dd0:	def43823          	sd	a5,-528(s0)
    80004dd4:	ac0d                	j	80005006 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd6:	00004517          	auipc	a0,0x4
    80004dda:	90a50513          	addi	a0,a0,-1782 # 800086e0 <syscalls+0x290>
    80004dde:	ffffb097          	auipc	ra,0xffffb
    80004de2:	766080e7          	jalr	1894(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de6:	8756                	mv	a4,s5
    80004de8:	012d86bb          	addw	a3,s11,s2
    80004dec:	4581                	li	a1,0
    80004dee:	8526                	mv	a0,s1
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	c94080e7          	jalr	-876(ra) # 80003a84 <readi>
    80004df8:	2501                	sext.w	a0,a0
    80004dfa:	1aaa9a63          	bne	s5,a0,80004fae <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfe:	6785                	lui	a5,0x1
    80004e00:	0127893b          	addw	s2,a5,s2
    80004e04:	77fd                	lui	a5,0xfffff
    80004e06:	01478a3b          	addw	s4,a5,s4
    80004e0a:	1f897563          	bgeu	s2,s8,80004ff4 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e0e:	02091593          	slli	a1,s2,0x20
    80004e12:	9181                	srli	a1,a1,0x20
    80004e14:	95ea                	add	a1,a1,s10
    80004e16:	855e                	mv	a0,s7
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	2a8080e7          	jalr	680(ra) # 800010c0 <walkaddr>
    80004e20:	862a                	mv	a2,a0
    if(pa == 0)
    80004e22:	d955                	beqz	a0,80004dd6 <exec+0xf0>
      n = PGSIZE;
    80004e24:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e26:	fd9a70e3          	bgeu	s4,s9,80004de6 <exec+0x100>
      n = sz - i;
    80004e2a:	8ad2                	mv	s5,s4
    80004e2c:	bf6d                	j	80004de6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2e:	4a01                	li	s4,0
  iunlockput(ip);
    80004e30:	8526                	mv	a0,s1
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	c00080e7          	jalr	-1024(ra) # 80003a32 <iunlockput>
  end_op();
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	3d8080e7          	jalr	984(ra) # 80004212 <end_op>
  p = myproc();
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	bcc080e7          	jalr	-1076(ra) # 80001a0e <myproc>
    80004e4a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e4c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e50:	6785                	lui	a5,0x1
    80004e52:	17fd                	addi	a5,a5,-1
    80004e54:	9a3e                	add	s4,s4,a5
    80004e56:	757d                	lui	a0,0xfffff
    80004e58:	00aa77b3          	and	a5,s4,a0
    80004e5c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e60:	4691                	li	a3,4
    80004e62:	6609                	lui	a2,0x2
    80004e64:	963e                	add	a2,a2,a5
    80004e66:	85be                	mv	a1,a5
    80004e68:	855e                	mv	a0,s7
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	60a080e7          	jalr	1546(ra) # 80001474 <uvmalloc>
    80004e72:	8b2a                	mv	s6,a0
  ip = 0;
    80004e74:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e76:	12050c63          	beqz	a0,80004fae <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e7a:	75f9                	lui	a1,0xffffe
    80004e7c:	95aa                	add	a1,a1,a0
    80004e7e:	855e                	mv	a0,s7
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	81a080e7          	jalr	-2022(ra) # 8000169a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e88:	7c7d                	lui	s8,0xfffff
    80004e8a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e8c:	e0043783          	ld	a5,-512(s0)
    80004e90:	6388                	ld	a0,0(a5)
    80004e92:	c535                	beqz	a0,80004efe <exec+0x218>
    80004e94:	e9040993          	addi	s3,s0,-368
    80004e98:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e9c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	014080e7          	jalr	20(ra) # 80000eb2 <strlen>
    80004ea6:	2505                	addiw	a0,a0,1
    80004ea8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eb0:	13896663          	bltu	s2,s8,80004fdc <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb4:	e0043d83          	ld	s11,-512(s0)
    80004eb8:	000dba03          	ld	s4,0(s11)
    80004ebc:	8552                	mv	a0,s4
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	ff4080e7          	jalr	-12(ra) # 80000eb2 <strlen>
    80004ec6:	0015069b          	addiw	a3,a0,1
    80004eca:	8652                	mv	a2,s4
    80004ecc:	85ca                	mv	a1,s2
    80004ece:	855e                	mv	a0,s7
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	7fc080e7          	jalr	2044(ra) # 800016cc <copyout>
    80004ed8:	10054663          	bltz	a0,80004fe4 <exec+0x2fe>
    ustack[argc] = sp;
    80004edc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ee0:	0485                	addi	s1,s1,1
    80004ee2:	008d8793          	addi	a5,s11,8
    80004ee6:	e0f43023          	sd	a5,-512(s0)
    80004eea:	008db503          	ld	a0,8(s11)
    80004eee:	c911                	beqz	a0,80004f02 <exec+0x21c>
    if(argc >= MAXARG)
    80004ef0:	09a1                	addi	s3,s3,8
    80004ef2:	fb3c96e3          	bne	s9,s3,80004e9e <exec+0x1b8>
  sz = sz1;
    80004ef6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004efa:	4481                	li	s1,0
    80004efc:	a84d                	j	80004fae <exec+0x2c8>
  sp = sz;
    80004efe:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f00:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f02:	00349793          	slli	a5,s1,0x3
    80004f06:	f9040713          	addi	a4,s0,-112
    80004f0a:	97ba                	add	a5,a5,a4
    80004f0c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f10:	00148693          	addi	a3,s1,1
    80004f14:	068e                	slli	a3,a3,0x3
    80004f16:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f1a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f1e:	01897663          	bgeu	s2,s8,80004f2a <exec+0x244>
  sz = sz1;
    80004f22:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f26:	4481                	li	s1,0
    80004f28:	a059                	j	80004fae <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f2a:	e9040613          	addi	a2,s0,-368
    80004f2e:	85ca                	mv	a1,s2
    80004f30:	855e                	mv	a0,s7
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	79a080e7          	jalr	1946(ra) # 800016cc <copyout>
    80004f3a:	0a054963          	bltz	a0,80004fec <exec+0x306>
  p->trapframe->a1 = sp;
    80004f3e:	058ab783          	ld	a5,88(s5)
    80004f42:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f46:	df843783          	ld	a5,-520(s0)
    80004f4a:	0007c703          	lbu	a4,0(a5)
    80004f4e:	cf11                	beqz	a4,80004f6a <exec+0x284>
    80004f50:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f52:	02f00693          	li	a3,47
    80004f56:	a039                	j	80004f64 <exec+0x27e>
      last = s+1;
    80004f58:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f5c:	0785                	addi	a5,a5,1
    80004f5e:	fff7c703          	lbu	a4,-1(a5)
    80004f62:	c701                	beqz	a4,80004f6a <exec+0x284>
    if(*s == '/')
    80004f64:	fed71ce3          	bne	a4,a3,80004f5c <exec+0x276>
    80004f68:	bfc5                	j	80004f58 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f6a:	4641                	li	a2,16
    80004f6c:	df843583          	ld	a1,-520(s0)
    80004f70:	158a8513          	addi	a0,s5,344
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	f0c080e7          	jalr	-244(ra) # 80000e80 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f7c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f80:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f84:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f88:	058ab783          	ld	a5,88(s5)
    80004f8c:	e6843703          	ld	a4,-408(s0)
    80004f90:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f92:	058ab783          	ld	a5,88(s5)
    80004f96:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f9a:	85ea                	mv	a1,s10
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	bd2080e7          	jalr	-1070(ra) # 80001b6e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa4:	0004851b          	sext.w	a0,s1
    80004fa8:	bbd9                	j	80004d7e <exec+0x98>
    80004faa:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fae:	e0843583          	ld	a1,-504(s0)
    80004fb2:	855e                	mv	a0,s7
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	bba080e7          	jalr	-1094(ra) # 80001b6e <proc_freepagetable>
  if(ip){
    80004fbc:	da0497e3          	bnez	s1,80004d6a <exec+0x84>
  return -1;
    80004fc0:	557d                	li	a0,-1
    80004fc2:	bb75                	j	80004d7e <exec+0x98>
    80004fc4:	e1443423          	sd	s4,-504(s0)
    80004fc8:	b7dd                	j	80004fae <exec+0x2c8>
    80004fca:	e1443423          	sd	s4,-504(s0)
    80004fce:	b7c5                	j	80004fae <exec+0x2c8>
    80004fd0:	e1443423          	sd	s4,-504(s0)
    80004fd4:	bfe9                	j	80004fae <exec+0x2c8>
    80004fd6:	e1443423          	sd	s4,-504(s0)
    80004fda:	bfd1                	j	80004fae <exec+0x2c8>
  sz = sz1;
    80004fdc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe0:	4481                	li	s1,0
    80004fe2:	b7f1                	j	80004fae <exec+0x2c8>
  sz = sz1;
    80004fe4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe8:	4481                	li	s1,0
    80004fea:	b7d1                	j	80004fae <exec+0x2c8>
  sz = sz1;
    80004fec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff0:	4481                	li	s1,0
    80004ff2:	bf75                	j	80004fae <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ff4:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff8:	2b05                	addiw	s6,s6,1
    80004ffa:	0389899b          	addiw	s3,s3,56
    80004ffe:	e8845783          	lhu	a5,-376(s0)
    80005002:	e2fb57e3          	bge	s6,a5,80004e30 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005006:	2981                	sext.w	s3,s3
    80005008:	03800713          	li	a4,56
    8000500c:	86ce                	mv	a3,s3
    8000500e:	e1840613          	addi	a2,s0,-488
    80005012:	4581                	li	a1,0
    80005014:	8526                	mv	a0,s1
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	a6e080e7          	jalr	-1426(ra) # 80003a84 <readi>
    8000501e:	03800793          	li	a5,56
    80005022:	f8f514e3          	bne	a0,a5,80004faa <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005026:	e1842783          	lw	a5,-488(s0)
    8000502a:	4705                	li	a4,1
    8000502c:	fce796e3          	bne	a5,a4,80004ff8 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005030:	e4043903          	ld	s2,-448(s0)
    80005034:	e3843783          	ld	a5,-456(s0)
    80005038:	f8f966e3          	bltu	s2,a5,80004fc4 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000503c:	e2843783          	ld	a5,-472(s0)
    80005040:	993e                	add	s2,s2,a5
    80005042:	f8f964e3          	bltu	s2,a5,80004fca <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005046:	df043703          	ld	a4,-528(s0)
    8000504a:	8ff9                	and	a5,a5,a4
    8000504c:	f3d1                	bnez	a5,80004fd0 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000504e:	e1c42503          	lw	a0,-484(s0)
    80005052:	00000097          	auipc	ra,0x0
    80005056:	c78080e7          	jalr	-904(ra) # 80004cca <flags2perm>
    8000505a:	86aa                	mv	a3,a0
    8000505c:	864a                	mv	a2,s2
    8000505e:	85d2                	mv	a1,s4
    80005060:	855e                	mv	a0,s7
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	412080e7          	jalr	1042(ra) # 80001474 <uvmalloc>
    8000506a:	e0a43423          	sd	a0,-504(s0)
    8000506e:	d525                	beqz	a0,80004fd6 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005070:	e2843d03          	ld	s10,-472(s0)
    80005074:	e2042d83          	lw	s11,-480(s0)
    80005078:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000507c:	f60c0ce3          	beqz	s8,80004ff4 <exec+0x30e>
    80005080:	8a62                	mv	s4,s8
    80005082:	4901                	li	s2,0
    80005084:	b369                	j	80004e0e <exec+0x128>

0000000080005086 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005086:	7179                	addi	sp,sp,-48
    80005088:	f406                	sd	ra,40(sp)
    8000508a:	f022                	sd	s0,32(sp)
    8000508c:	ec26                	sd	s1,24(sp)
    8000508e:	e84a                	sd	s2,16(sp)
    80005090:	1800                	addi	s0,sp,48
    80005092:	892e                	mv	s2,a1
    80005094:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005096:	fdc40593          	addi	a1,s0,-36
    8000509a:	ffffe097          	auipc	ra,0xffffe
    8000509e:	b54080e7          	jalr	-1196(ra) # 80002bee <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a2:	fdc42703          	lw	a4,-36(s0)
    800050a6:	47bd                	li	a5,15
    800050a8:	02e7eb63          	bltu	a5,a4,800050de <argfd+0x58>
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	962080e7          	jalr	-1694(ra) # 80001a0e <myproc>
    800050b4:	fdc42703          	lw	a4,-36(s0)
    800050b8:	01a70793          	addi	a5,a4,26
    800050bc:	078e                	slli	a5,a5,0x3
    800050be:	953e                	add	a0,a0,a5
    800050c0:	611c                	ld	a5,0(a0)
    800050c2:	c385                	beqz	a5,800050e2 <argfd+0x5c>
    return -1;
  if(pfd)
    800050c4:	00090463          	beqz	s2,800050cc <argfd+0x46>
    *pfd = fd;
    800050c8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050cc:	4501                	li	a0,0
  if(pf)
    800050ce:	c091                	beqz	s1,800050d2 <argfd+0x4c>
    *pf = f;
    800050d0:	e09c                	sd	a5,0(s1)
}
    800050d2:	70a2                	ld	ra,40(sp)
    800050d4:	7402                	ld	s0,32(sp)
    800050d6:	64e2                	ld	s1,24(sp)
    800050d8:	6942                	ld	s2,16(sp)
    800050da:	6145                	addi	sp,sp,48
    800050dc:	8082                	ret
    return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	bfcd                	j	800050d2 <argfd+0x4c>
    800050e2:	557d                	li	a0,-1
    800050e4:	b7fd                	j	800050d2 <argfd+0x4c>

00000000800050e6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e6:	1101                	addi	sp,sp,-32
    800050e8:	ec06                	sd	ra,24(sp)
    800050ea:	e822                	sd	s0,16(sp)
    800050ec:	e426                	sd	s1,8(sp)
    800050ee:	1000                	addi	s0,sp,32
    800050f0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	91c080e7          	jalr	-1764(ra) # 80001a0e <myproc>
    800050fa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050fc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd160>
    80005100:	4501                	li	a0,0
    80005102:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005104:	6398                	ld	a4,0(a5)
    80005106:	cb19                	beqz	a4,8000511c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005108:	2505                	addiw	a0,a0,1
    8000510a:	07a1                	addi	a5,a5,8
    8000510c:	fed51ce3          	bne	a0,a3,80005104 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005110:	557d                	li	a0,-1
}
    80005112:	60e2                	ld	ra,24(sp)
    80005114:	6442                	ld	s0,16(sp)
    80005116:	64a2                	ld	s1,8(sp)
    80005118:	6105                	addi	sp,sp,32
    8000511a:	8082                	ret
      p->ofile[fd] = f;
    8000511c:	01a50793          	addi	a5,a0,26
    80005120:	078e                	slli	a5,a5,0x3
    80005122:	963e                	add	a2,a2,a5
    80005124:	e204                	sd	s1,0(a2)
      return fd;
    80005126:	b7f5                	j	80005112 <fdalloc+0x2c>

0000000080005128 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005128:	715d                	addi	sp,sp,-80
    8000512a:	e486                	sd	ra,72(sp)
    8000512c:	e0a2                	sd	s0,64(sp)
    8000512e:	fc26                	sd	s1,56(sp)
    80005130:	f84a                	sd	s2,48(sp)
    80005132:	f44e                	sd	s3,40(sp)
    80005134:	f052                	sd	s4,32(sp)
    80005136:	ec56                	sd	s5,24(sp)
    80005138:	e85a                	sd	s6,16(sp)
    8000513a:	0880                	addi	s0,sp,80
    8000513c:	8b2e                	mv	s6,a1
    8000513e:	89b2                	mv	s3,a2
    80005140:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005142:	fb040593          	addi	a1,s0,-80
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	e4e080e7          	jalr	-434(ra) # 80003f94 <nameiparent>
    8000514e:	84aa                	mv	s1,a0
    80005150:	16050063          	beqz	a0,800052b0 <create+0x188>
    return 0;

  ilock(dp);
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	67c080e7          	jalr	1660(ra) # 800037d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000515c:	4601                	li	a2,0
    8000515e:	fb040593          	addi	a1,s0,-80
    80005162:	8526                	mv	a0,s1
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	b50080e7          	jalr	-1200(ra) # 80003cb4 <dirlookup>
    8000516c:	8aaa                	mv	s5,a0
    8000516e:	c931                	beqz	a0,800051c2 <create+0x9a>
    iunlockput(dp);
    80005170:	8526                	mv	a0,s1
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	8c0080e7          	jalr	-1856(ra) # 80003a32 <iunlockput>
    ilock(ip);
    8000517a:	8556                	mv	a0,s5
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	654080e7          	jalr	1620(ra) # 800037d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005184:	000b059b          	sext.w	a1,s6
    80005188:	4789                	li	a5,2
    8000518a:	02f59563          	bne	a1,a5,800051b4 <create+0x8c>
    8000518e:	044ad783          	lhu	a5,68(s5)
    80005192:	37f9                	addiw	a5,a5,-2
    80005194:	17c2                	slli	a5,a5,0x30
    80005196:	93c1                	srli	a5,a5,0x30
    80005198:	4705                	li	a4,1
    8000519a:	00f76d63          	bltu	a4,a5,800051b4 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000519e:	8556                	mv	a0,s5
    800051a0:	60a6                	ld	ra,72(sp)
    800051a2:	6406                	ld	s0,64(sp)
    800051a4:	74e2                	ld	s1,56(sp)
    800051a6:	7942                	ld	s2,48(sp)
    800051a8:	79a2                	ld	s3,40(sp)
    800051aa:	7a02                	ld	s4,32(sp)
    800051ac:	6ae2                	ld	s5,24(sp)
    800051ae:	6b42                	ld	s6,16(sp)
    800051b0:	6161                	addi	sp,sp,80
    800051b2:	8082                	ret
    iunlockput(ip);
    800051b4:	8556                	mv	a0,s5
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	87c080e7          	jalr	-1924(ra) # 80003a32 <iunlockput>
    return 0;
    800051be:	4a81                	li	s5,0
    800051c0:	bff9                	j	8000519e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051c2:	85da                	mv	a1,s6
    800051c4:	4088                	lw	a0,0(s1)
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	46e080e7          	jalr	1134(ra) # 80003634 <ialloc>
    800051ce:	8a2a                	mv	s4,a0
    800051d0:	c921                	beqz	a0,80005220 <create+0xf8>
  ilock(ip);
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	5fe080e7          	jalr	1534(ra) # 800037d0 <ilock>
  ip->major = major;
    800051da:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051de:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051e2:	4785                	li	a5,1
    800051e4:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051e8:	8552                	mv	a0,s4
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	51c080e7          	jalr	1308(ra) # 80003706 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f2:	000b059b          	sext.w	a1,s6
    800051f6:	4785                	li	a5,1
    800051f8:	02f58b63          	beq	a1,a5,8000522e <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fc:	004a2603          	lw	a2,4(s4)
    80005200:	fb040593          	addi	a1,s0,-80
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	cbe080e7          	jalr	-834(ra) # 80003ec4 <dirlink>
    8000520e:	06054f63          	bltz	a0,8000528c <create+0x164>
  iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	81e080e7          	jalr	-2018(ra) # 80003a32 <iunlockput>
  return ip;
    8000521c:	8ad2                	mv	s5,s4
    8000521e:	b741                	j	8000519e <create+0x76>
    iunlockput(dp);
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	810080e7          	jalr	-2032(ra) # 80003a32 <iunlockput>
    return 0;
    8000522a:	8ad2                	mv	s5,s4
    8000522c:	bf8d                	j	8000519e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000522e:	004a2603          	lw	a2,4(s4)
    80005232:	00003597          	auipc	a1,0x3
    80005236:	4ce58593          	addi	a1,a1,1230 # 80008700 <syscalls+0x2b0>
    8000523a:	8552                	mv	a0,s4
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	c88080e7          	jalr	-888(ra) # 80003ec4 <dirlink>
    80005244:	04054463          	bltz	a0,8000528c <create+0x164>
    80005248:	40d0                	lw	a2,4(s1)
    8000524a:	00003597          	auipc	a1,0x3
    8000524e:	4be58593          	addi	a1,a1,1214 # 80008708 <syscalls+0x2b8>
    80005252:	8552                	mv	a0,s4
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	c70080e7          	jalr	-912(ra) # 80003ec4 <dirlink>
    8000525c:	02054863          	bltz	a0,8000528c <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005260:	004a2603          	lw	a2,4(s4)
    80005264:	fb040593          	addi	a1,s0,-80
    80005268:	8526                	mv	a0,s1
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	c5a080e7          	jalr	-934(ra) # 80003ec4 <dirlink>
    80005272:	00054d63          	bltz	a0,8000528c <create+0x164>
    dp->nlink++;  // for ".."
    80005276:	04a4d783          	lhu	a5,74(s1)
    8000527a:	2785                	addiw	a5,a5,1
    8000527c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	484080e7          	jalr	1156(ra) # 80003706 <iupdate>
    8000528a:	b761                	j	80005212 <create+0xea>
  ip->nlink = 0;
    8000528c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005290:	8552                	mv	a0,s4
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	474080e7          	jalr	1140(ra) # 80003706 <iupdate>
  iunlockput(ip);
    8000529a:	8552                	mv	a0,s4
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	796080e7          	jalr	1942(ra) # 80003a32 <iunlockput>
  iunlockput(dp);
    800052a4:	8526                	mv	a0,s1
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	78c080e7          	jalr	1932(ra) # 80003a32 <iunlockput>
  return 0;
    800052ae:	bdc5                	j	8000519e <create+0x76>
    return 0;
    800052b0:	8aaa                	mv	s5,a0
    800052b2:	b5f5                	j	8000519e <create+0x76>

00000000800052b4 <sys_dup>:
{
    800052b4:	7179                	addi	sp,sp,-48
    800052b6:	f406                	sd	ra,40(sp)
    800052b8:	f022                	sd	s0,32(sp)
    800052ba:	ec26                	sd	s1,24(sp)
    800052bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052be:	fd840613          	addi	a2,s0,-40
    800052c2:	4581                	li	a1,0
    800052c4:	4501                	li	a0,0
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	dc0080e7          	jalr	-576(ra) # 80005086 <argfd>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052d0:	02054363          	bltz	a0,800052f6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d4:	fd843503          	ld	a0,-40(s0)
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	e0e080e7          	jalr	-498(ra) # 800050e6 <fdalloc>
    800052e0:	84aa                	mv	s1,a0
    return -1;
    800052e2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e4:	00054963          	bltz	a0,800052f6 <sys_dup+0x42>
  filedup(f);
    800052e8:	fd843503          	ld	a0,-40(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	320080e7          	jalr	800(ra) # 8000460c <filedup>
  return fd;
    800052f4:	87a6                	mv	a5,s1
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	64e2                	ld	s1,24(sp)
    800052fe:	6145                	addi	sp,sp,48
    80005300:	8082                	ret

0000000080005302 <sys_read>:
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000530a:	fd840593          	addi	a1,s0,-40
    8000530e:	4505                	li	a0,1
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	8fe080e7          	jalr	-1794(ra) # 80002c0e <argaddr>
  argint(2, &n);
    80005318:	fe440593          	addi	a1,s0,-28
    8000531c:	4509                	li	a0,2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	8d0080e7          	jalr	-1840(ra) # 80002bee <argint>
  if(argfd(0, 0, &f) < 0)
    80005326:	fe840613          	addi	a2,s0,-24
    8000532a:	4581                	li	a1,0
    8000532c:	4501                	li	a0,0
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	d58080e7          	jalr	-680(ra) # 80005086 <argfd>
    80005336:	87aa                	mv	a5,a0
    return -1;
    80005338:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000533a:	0007cc63          	bltz	a5,80005352 <sys_read+0x50>
  return fileread(f, p, n);
    8000533e:	fe442603          	lw	a2,-28(s0)
    80005342:	fd843583          	ld	a1,-40(s0)
    80005346:	fe843503          	ld	a0,-24(s0)
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	44e080e7          	jalr	1102(ra) # 80004798 <fileread>
}
    80005352:	70a2                	ld	ra,40(sp)
    80005354:	7402                	ld	s0,32(sp)
    80005356:	6145                	addi	sp,sp,48
    80005358:	8082                	ret

000000008000535a <sys_write>:
{
    8000535a:	7179                	addi	sp,sp,-48
    8000535c:	f406                	sd	ra,40(sp)
    8000535e:	f022                	sd	s0,32(sp)
    80005360:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005362:	fd840593          	addi	a1,s0,-40
    80005366:	4505                	li	a0,1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	8a6080e7          	jalr	-1882(ra) # 80002c0e <argaddr>
  argint(2, &n);
    80005370:	fe440593          	addi	a1,s0,-28
    80005374:	4509                	li	a0,2
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	878080e7          	jalr	-1928(ra) # 80002bee <argint>
  if(argfd(0, 0, &f) < 0)
    8000537e:	fe840613          	addi	a2,s0,-24
    80005382:	4581                	li	a1,0
    80005384:	4501                	li	a0,0
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	d00080e7          	jalr	-768(ra) # 80005086 <argfd>
    8000538e:	87aa                	mv	a5,a0
    return -1;
    80005390:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005392:	0007cc63          	bltz	a5,800053aa <sys_write+0x50>
  return filewrite(f, p, n);
    80005396:	fe442603          	lw	a2,-28(s0)
    8000539a:	fd843583          	ld	a1,-40(s0)
    8000539e:	fe843503          	ld	a0,-24(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	4b8080e7          	jalr	1208(ra) # 8000485a <filewrite>
}
    800053aa:	70a2                	ld	ra,40(sp)
    800053ac:	7402                	ld	s0,32(sp)
    800053ae:	6145                	addi	sp,sp,48
    800053b0:	8082                	ret

00000000800053b2 <sys_close>:
{
    800053b2:	1101                	addi	sp,sp,-32
    800053b4:	ec06                	sd	ra,24(sp)
    800053b6:	e822                	sd	s0,16(sp)
    800053b8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053ba:	fe040613          	addi	a2,s0,-32
    800053be:	fec40593          	addi	a1,s0,-20
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	cc2080e7          	jalr	-830(ra) # 80005086 <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ce:	02054463          	bltz	a0,800053f6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	63c080e7          	jalr	1596(ra) # 80001a0e <myproc>
    800053da:	fec42783          	lw	a5,-20(s0)
    800053de:	07e9                	addi	a5,a5,26
    800053e0:	078e                	slli	a5,a5,0x3
    800053e2:	97aa                	add	a5,a5,a0
    800053e4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e8:	fe043503          	ld	a0,-32(s0)
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	272080e7          	jalr	626(ra) # 8000465e <fileclose>
  return 0;
    800053f4:	4781                	li	a5,0
}
    800053f6:	853e                	mv	a0,a5
    800053f8:	60e2                	ld	ra,24(sp)
    800053fa:	6442                	ld	s0,16(sp)
    800053fc:	6105                	addi	sp,sp,32
    800053fe:	8082                	ret

0000000080005400 <sys_fstat>:
{
    80005400:	1101                	addi	sp,sp,-32
    80005402:	ec06                	sd	ra,24(sp)
    80005404:	e822                	sd	s0,16(sp)
    80005406:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005408:	fe040593          	addi	a1,s0,-32
    8000540c:	4505                	li	a0,1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	800080e7          	jalr	-2048(ra) # 80002c0e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005416:	fe840613          	addi	a2,s0,-24
    8000541a:	4581                	li	a1,0
    8000541c:	4501                	li	a0,0
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	c68080e7          	jalr	-920(ra) # 80005086 <argfd>
    80005426:	87aa                	mv	a5,a0
    return -1;
    80005428:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000542a:	0007ca63          	bltz	a5,8000543e <sys_fstat+0x3e>
  return filestat(f, st);
    8000542e:	fe043583          	ld	a1,-32(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	2f0080e7          	jalr	752(ra) # 80004726 <filestat>
}
    8000543e:	60e2                	ld	ra,24(sp)
    80005440:	6442                	ld	s0,16(sp)
    80005442:	6105                	addi	sp,sp,32
    80005444:	8082                	ret

0000000080005446 <sys_link>:
{
    80005446:	7169                	addi	sp,sp,-304
    80005448:	f606                	sd	ra,296(sp)
    8000544a:	f222                	sd	s0,288(sp)
    8000544c:	ee26                	sd	s1,280(sp)
    8000544e:	ea4a                	sd	s2,272(sp)
    80005450:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005452:	08000613          	li	a2,128
    80005456:	ed040593          	addi	a1,s0,-304
    8000545a:	4501                	li	a0,0
    8000545c:	ffffd097          	auipc	ra,0xffffd
    80005460:	7d2080e7          	jalr	2002(ra) # 80002c2e <argstr>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005466:	10054e63          	bltz	a0,80005582 <sys_link+0x13c>
    8000546a:	08000613          	li	a2,128
    8000546e:	f5040593          	addi	a1,s0,-176
    80005472:	4505                	li	a0,1
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	7ba080e7          	jalr	1978(ra) # 80002c2e <argstr>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547e:	10054263          	bltz	a0,80005582 <sys_link+0x13c>
  begin_op();
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	d10080e7          	jalr	-752(ra) # 80004192 <begin_op>
  if((ip = namei(old)) == 0){
    8000548a:	ed040513          	addi	a0,s0,-304
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	ae8080e7          	jalr	-1304(ra) # 80003f76 <namei>
    80005496:	84aa                	mv	s1,a0
    80005498:	c551                	beqz	a0,80005524 <sys_link+0xde>
  ilock(ip);
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	336080e7          	jalr	822(ra) # 800037d0 <ilock>
  if(ip->type == T_DIR){
    800054a2:	04449703          	lh	a4,68(s1)
    800054a6:	4785                	li	a5,1
    800054a8:	08f70463          	beq	a4,a5,80005530 <sys_link+0xea>
  ip->nlink++;
    800054ac:	04a4d783          	lhu	a5,74(s1)
    800054b0:	2785                	addiw	a5,a5,1
    800054b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	24e080e7          	jalr	590(ra) # 80003706 <iupdate>
  iunlock(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	3d0080e7          	jalr	976(ra) # 80003892 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ca:	fd040593          	addi	a1,s0,-48
    800054ce:	f5040513          	addi	a0,s0,-176
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	ac2080e7          	jalr	-1342(ra) # 80003f94 <nameiparent>
    800054da:	892a                	mv	s2,a0
    800054dc:	c935                	beqz	a0,80005550 <sys_link+0x10a>
  ilock(dp);
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	2f2080e7          	jalr	754(ra) # 800037d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054e6:	00092703          	lw	a4,0(s2)
    800054ea:	409c                	lw	a5,0(s1)
    800054ec:	04f71d63          	bne	a4,a5,80005546 <sys_link+0x100>
    800054f0:	40d0                	lw	a2,4(s1)
    800054f2:	fd040593          	addi	a1,s0,-48
    800054f6:	854a                	mv	a0,s2
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	9cc080e7          	jalr	-1588(ra) # 80003ec4 <dirlink>
    80005500:	04054363          	bltz	a0,80005546 <sys_link+0x100>
  iunlockput(dp);
    80005504:	854a                	mv	a0,s2
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	52c080e7          	jalr	1324(ra) # 80003a32 <iunlockput>
  iput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	47a080e7          	jalr	1146(ra) # 8000398a <iput>
  end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cfa080e7          	jalr	-774(ra) # 80004212 <end_op>
  return 0;
    80005520:	4781                	li	a5,0
    80005522:	a085                	j	80005582 <sys_link+0x13c>
    end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	cee080e7          	jalr	-786(ra) # 80004212 <end_op>
    return -1;
    8000552c:	57fd                	li	a5,-1
    8000552e:	a891                	j	80005582 <sys_link+0x13c>
    iunlockput(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	500080e7          	jalr	1280(ra) # 80003a32 <iunlockput>
    end_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	cd8080e7          	jalr	-808(ra) # 80004212 <end_op>
    return -1;
    80005542:	57fd                	li	a5,-1
    80005544:	a83d                	j	80005582 <sys_link+0x13c>
    iunlockput(dp);
    80005546:	854a                	mv	a0,s2
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	4ea080e7          	jalr	1258(ra) # 80003a32 <iunlockput>
  ilock(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	27e080e7          	jalr	638(ra) # 800037d0 <ilock>
  ip->nlink--;
    8000555a:	04a4d783          	lhu	a5,74(s1)
    8000555e:	37fd                	addiw	a5,a5,-1
    80005560:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	1a0080e7          	jalr	416(ra) # 80003706 <iupdate>
  iunlockput(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	4c2080e7          	jalr	1218(ra) # 80003a32 <iunlockput>
  end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	c9a080e7          	jalr	-870(ra) # 80004212 <end_op>
  return -1;
    80005580:	57fd                	li	a5,-1
}
    80005582:	853e                	mv	a0,a5
    80005584:	70b2                	ld	ra,296(sp)
    80005586:	7412                	ld	s0,288(sp)
    80005588:	64f2                	ld	s1,280(sp)
    8000558a:	6952                	ld	s2,272(sp)
    8000558c:	6155                	addi	sp,sp,304
    8000558e:	8082                	ret

0000000080005590 <sys_unlink>:
{
    80005590:	7151                	addi	sp,sp,-240
    80005592:	f586                	sd	ra,232(sp)
    80005594:	f1a2                	sd	s0,224(sp)
    80005596:	eda6                	sd	s1,216(sp)
    80005598:	e9ca                	sd	s2,208(sp)
    8000559a:	e5ce                	sd	s3,200(sp)
    8000559c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000559e:	08000613          	li	a2,128
    800055a2:	f3040593          	addi	a1,s0,-208
    800055a6:	4501                	li	a0,0
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	686080e7          	jalr	1670(ra) # 80002c2e <argstr>
    800055b0:	18054163          	bltz	a0,80005732 <sys_unlink+0x1a2>
  begin_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	bde080e7          	jalr	-1058(ra) # 80004192 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055bc:	fb040593          	addi	a1,s0,-80
    800055c0:	f3040513          	addi	a0,s0,-208
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	9d0080e7          	jalr	-1584(ra) # 80003f94 <nameiparent>
    800055cc:	84aa                	mv	s1,a0
    800055ce:	c979                	beqz	a0,800056a4 <sys_unlink+0x114>
  ilock(dp);
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	200080e7          	jalr	512(ra) # 800037d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055d8:	00003597          	auipc	a1,0x3
    800055dc:	12858593          	addi	a1,a1,296 # 80008700 <syscalls+0x2b0>
    800055e0:	fb040513          	addi	a0,s0,-80
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	6b6080e7          	jalr	1718(ra) # 80003c9a <namecmp>
    800055ec:	14050a63          	beqz	a0,80005740 <sys_unlink+0x1b0>
    800055f0:	00003597          	auipc	a1,0x3
    800055f4:	11858593          	addi	a1,a1,280 # 80008708 <syscalls+0x2b8>
    800055f8:	fb040513          	addi	a0,s0,-80
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	69e080e7          	jalr	1694(ra) # 80003c9a <namecmp>
    80005604:	12050e63          	beqz	a0,80005740 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005608:	f2c40613          	addi	a2,s0,-212
    8000560c:	fb040593          	addi	a1,s0,-80
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	6a2080e7          	jalr	1698(ra) # 80003cb4 <dirlookup>
    8000561a:	892a                	mv	s2,a0
    8000561c:	12050263          	beqz	a0,80005740 <sys_unlink+0x1b0>
  ilock(ip);
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	1b0080e7          	jalr	432(ra) # 800037d0 <ilock>
  if(ip->nlink < 1)
    80005628:	04a91783          	lh	a5,74(s2)
    8000562c:	08f05263          	blez	a5,800056b0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005630:	04491703          	lh	a4,68(s2)
    80005634:	4785                	li	a5,1
    80005636:	08f70563          	beq	a4,a5,800056c0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000563a:	4641                	li	a2,16
    8000563c:	4581                	li	a1,0
    8000563e:	fc040513          	addi	a0,s0,-64
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	6ec080e7          	jalr	1772(ra) # 80000d2e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564a:	4741                	li	a4,16
    8000564c:	f2c42683          	lw	a3,-212(s0)
    80005650:	fc040613          	addi	a2,s0,-64
    80005654:	4581                	li	a1,0
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	524080e7          	jalr	1316(ra) # 80003b7c <writei>
    80005660:	47c1                	li	a5,16
    80005662:	0af51563          	bne	a0,a5,8000570c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005666:	04491703          	lh	a4,68(s2)
    8000566a:	4785                	li	a5,1
    8000566c:	0af70863          	beq	a4,a5,8000571c <sys_unlink+0x18c>
  iunlockput(dp);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	3c0080e7          	jalr	960(ra) # 80003a32 <iunlockput>
  ip->nlink--;
    8000567a:	04a95783          	lhu	a5,74(s2)
    8000567e:	37fd                	addiw	a5,a5,-1
    80005680:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	080080e7          	jalr	128(ra) # 80003706 <iupdate>
  iunlockput(ip);
    8000568e:	854a                	mv	a0,s2
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	3a2080e7          	jalr	930(ra) # 80003a32 <iunlockput>
  end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	b7a080e7          	jalr	-1158(ra) # 80004212 <end_op>
  return 0;
    800056a0:	4501                	li	a0,0
    800056a2:	a84d                	j	80005754 <sys_unlink+0x1c4>
    end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	b6e080e7          	jalr	-1170(ra) # 80004212 <end_op>
    return -1;
    800056ac:	557d                	li	a0,-1
    800056ae:	a05d                	j	80005754 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056b0:	00003517          	auipc	a0,0x3
    800056b4:	06050513          	addi	a0,a0,96 # 80008710 <syscalls+0x2c0>
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	e8c080e7          	jalr	-372(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c0:	04c92703          	lw	a4,76(s2)
    800056c4:	02000793          	li	a5,32
    800056c8:	f6e7f9e3          	bgeu	a5,a4,8000563a <sys_unlink+0xaa>
    800056cc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d0:	4741                	li	a4,16
    800056d2:	86ce                	mv	a3,s3
    800056d4:	f1840613          	addi	a2,s0,-232
    800056d8:	4581                	li	a1,0
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	3a8080e7          	jalr	936(ra) # 80003a84 <readi>
    800056e4:	47c1                	li	a5,16
    800056e6:	00f51b63          	bne	a0,a5,800056fc <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ea:	f1845783          	lhu	a5,-232(s0)
    800056ee:	e7a1                	bnez	a5,80005736 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f0:	29c1                	addiw	s3,s3,16
    800056f2:	04c92783          	lw	a5,76(s2)
    800056f6:	fcf9ede3          	bltu	s3,a5,800056d0 <sys_unlink+0x140>
    800056fa:	b781                	j	8000563a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056fc:	00003517          	auipc	a0,0x3
    80005700:	02c50513          	addi	a0,a0,44 # 80008728 <syscalls+0x2d8>
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	e40080e7          	jalr	-448(ra) # 80000544 <panic>
    panic("unlink: writei");
    8000570c:	00003517          	auipc	a0,0x3
    80005710:	03450513          	addi	a0,a0,52 # 80008740 <syscalls+0x2f0>
    80005714:	ffffb097          	auipc	ra,0xffffb
    80005718:	e30080e7          	jalr	-464(ra) # 80000544 <panic>
    dp->nlink--;
    8000571c:	04a4d783          	lhu	a5,74(s1)
    80005720:	37fd                	addiw	a5,a5,-1
    80005722:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	fde080e7          	jalr	-34(ra) # 80003706 <iupdate>
    80005730:	b781                	j	80005670 <sys_unlink+0xe0>
    return -1;
    80005732:	557d                	li	a0,-1
    80005734:	a005                	j	80005754 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	2fa080e7          	jalr	762(ra) # 80003a32 <iunlockput>
  iunlockput(dp);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	2f0080e7          	jalr	752(ra) # 80003a32 <iunlockput>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	ac8080e7          	jalr	-1336(ra) # 80004212 <end_op>
  return -1;
    80005752:	557d                	li	a0,-1
}
    80005754:	70ae                	ld	ra,232(sp)
    80005756:	740e                	ld	s0,224(sp)
    80005758:	64ee                	ld	s1,216(sp)
    8000575a:	694e                	ld	s2,208(sp)
    8000575c:	69ae                	ld	s3,200(sp)
    8000575e:	616d                	addi	sp,sp,240
    80005760:	8082                	ret

0000000080005762 <sys_open>:

uint64
sys_open(void)
{
    80005762:	7131                	addi	sp,sp,-192
    80005764:	fd06                	sd	ra,184(sp)
    80005766:	f922                	sd	s0,176(sp)
    80005768:	f526                	sd	s1,168(sp)
    8000576a:	f14a                	sd	s2,160(sp)
    8000576c:	ed4e                	sd	s3,152(sp)
    8000576e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005770:	f4c40593          	addi	a1,s0,-180
    80005774:	4505                	li	a0,1
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	478080e7          	jalr	1144(ra) # 80002bee <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000577e:	08000613          	li	a2,128
    80005782:	f5040593          	addi	a1,s0,-176
    80005786:	4501                	li	a0,0
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	4a6080e7          	jalr	1190(ra) # 80002c2e <argstr>
    80005790:	87aa                	mv	a5,a0
    return -1;
    80005792:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005794:	0a07c963          	bltz	a5,80005846 <sys_open+0xe4>

  begin_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	9fa080e7          	jalr	-1542(ra) # 80004192 <begin_op>

  if(omode & O_CREATE){
    800057a0:	f4c42783          	lw	a5,-180(s0)
    800057a4:	2007f793          	andi	a5,a5,512
    800057a8:	cfc5                	beqz	a5,80005860 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057aa:	4681                	li	a3,0
    800057ac:	4601                	li	a2,0
    800057ae:	4589                	li	a1,2
    800057b0:	f5040513          	addi	a0,s0,-176
    800057b4:	00000097          	auipc	ra,0x0
    800057b8:	974080e7          	jalr	-1676(ra) # 80005128 <create>
    800057bc:	84aa                	mv	s1,a0
    if(ip == 0){
    800057be:	c959                	beqz	a0,80005854 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057c0:	04449703          	lh	a4,68(s1)
    800057c4:	478d                	li	a5,3
    800057c6:	00f71763          	bne	a4,a5,800057d4 <sys_open+0x72>
    800057ca:	0464d703          	lhu	a4,70(s1)
    800057ce:	47a5                	li	a5,9
    800057d0:	0ce7ed63          	bltu	a5,a4,800058aa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	dce080e7          	jalr	-562(ra) # 800045a2 <filealloc>
    800057dc:	89aa                	mv	s3,a0
    800057de:	10050363          	beqz	a0,800058e4 <sys_open+0x182>
    800057e2:	00000097          	auipc	ra,0x0
    800057e6:	904080e7          	jalr	-1788(ra) # 800050e6 <fdalloc>
    800057ea:	892a                	mv	s2,a0
    800057ec:	0e054763          	bltz	a0,800058da <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057f0:	04449703          	lh	a4,68(s1)
    800057f4:	478d                	li	a5,3
    800057f6:	0cf70563          	beq	a4,a5,800058c0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057fa:	4789                	li	a5,2
    800057fc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005800:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005804:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005808:	f4c42783          	lw	a5,-180(s0)
    8000580c:	0017c713          	xori	a4,a5,1
    80005810:	8b05                	andi	a4,a4,1
    80005812:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005816:	0037f713          	andi	a4,a5,3
    8000581a:	00e03733          	snez	a4,a4
    8000581e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005822:	4007f793          	andi	a5,a5,1024
    80005826:	c791                	beqz	a5,80005832 <sys_open+0xd0>
    80005828:	04449703          	lh	a4,68(s1)
    8000582c:	4789                	li	a5,2
    8000582e:	0af70063          	beq	a4,a5,800058ce <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	05e080e7          	jalr	94(ra) # 80003892 <iunlock>
  end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	9d6080e7          	jalr	-1578(ra) # 80004212 <end_op>

  return fd;
    80005844:	854a                	mv	a0,s2
}
    80005846:	70ea                	ld	ra,184(sp)
    80005848:	744a                	ld	s0,176(sp)
    8000584a:	74aa                	ld	s1,168(sp)
    8000584c:	790a                	ld	s2,160(sp)
    8000584e:	69ea                	ld	s3,152(sp)
    80005850:	6129                	addi	sp,sp,192
    80005852:	8082                	ret
      end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	9be080e7          	jalr	-1602(ra) # 80004212 <end_op>
      return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	b7e5                	j	80005846 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005860:	f5040513          	addi	a0,s0,-176
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	712080e7          	jalr	1810(ra) # 80003f76 <namei>
    8000586c:	84aa                	mv	s1,a0
    8000586e:	c905                	beqz	a0,8000589e <sys_open+0x13c>
    ilock(ip);
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	f60080e7          	jalr	-160(ra) # 800037d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005878:	04449703          	lh	a4,68(s1)
    8000587c:	4785                	li	a5,1
    8000587e:	f4f711e3          	bne	a4,a5,800057c0 <sys_open+0x5e>
    80005882:	f4c42783          	lw	a5,-180(s0)
    80005886:	d7b9                	beqz	a5,800057d4 <sys_open+0x72>
      iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	1a8080e7          	jalr	424(ra) # 80003a32 <iunlockput>
      end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	980080e7          	jalr	-1664(ra) # 80004212 <end_op>
      return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b76d                	j	80005846 <sys_open+0xe4>
      end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	974080e7          	jalr	-1676(ra) # 80004212 <end_op>
      return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	bf79                	j	80005846 <sys_open+0xe4>
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	186080e7          	jalr	390(ra) # 80003a32 <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	95e080e7          	jalr	-1698(ra) # 80004212 <end_op>
    return -1;
    800058bc:	557d                	li	a0,-1
    800058be:	b761                	j	80005846 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058c0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c4:	04649783          	lh	a5,70(s1)
    800058c8:	02f99223          	sh	a5,36(s3)
    800058cc:	bf25                	j	80005804 <sys_open+0xa2>
    itrunc(ip);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	00e080e7          	jalr	14(ra) # 800038de <itrunc>
    800058d8:	bfa9                	j	80005832 <sys_open+0xd0>
      fileclose(f);
    800058da:	854e                	mv	a0,s3
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	d82080e7          	jalr	-638(ra) # 8000465e <fileclose>
    iunlockput(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	14c080e7          	jalr	332(ra) # 80003a32 <iunlockput>
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	924080e7          	jalr	-1756(ra) # 80004212 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	b7b9                	j	80005846 <sys_open+0xe4>

00000000800058fa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058fa:	7175                	addi	sp,sp,-144
    800058fc:	e506                	sd	ra,136(sp)
    800058fe:	e122                	sd	s0,128(sp)
    80005900:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	890080e7          	jalr	-1904(ra) # 80004192 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000590a:	08000613          	li	a2,128
    8000590e:	f7040593          	addi	a1,s0,-144
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	31a080e7          	jalr	794(ra) # 80002c2e <argstr>
    8000591c:	02054963          	bltz	a0,8000594e <sys_mkdir+0x54>
    80005920:	4681                	li	a3,0
    80005922:	4601                	li	a2,0
    80005924:	4585                	li	a1,1
    80005926:	f7040513          	addi	a0,s0,-144
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	7fe080e7          	jalr	2046(ra) # 80005128 <create>
    80005932:	cd11                	beqz	a0,8000594e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	0fe080e7          	jalr	254(ra) # 80003a32 <iunlockput>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	8d6080e7          	jalr	-1834(ra) # 80004212 <end_op>
  return 0;
    80005944:	4501                	li	a0,0
}
    80005946:	60aa                	ld	ra,136(sp)
    80005948:	640a                	ld	s0,128(sp)
    8000594a:	6149                	addi	sp,sp,144
    8000594c:	8082                	ret
    end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	8c4080e7          	jalr	-1852(ra) # 80004212 <end_op>
    return -1;
    80005956:	557d                	li	a0,-1
    80005958:	b7fd                	j	80005946 <sys_mkdir+0x4c>

000000008000595a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000595a:	7135                	addi	sp,sp,-160
    8000595c:	ed06                	sd	ra,152(sp)
    8000595e:	e922                	sd	s0,144(sp)
    80005960:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	830080e7          	jalr	-2000(ra) # 80004192 <begin_op>
  argint(1, &major);
    8000596a:	f6c40593          	addi	a1,s0,-148
    8000596e:	4505                	li	a0,1
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	27e080e7          	jalr	638(ra) # 80002bee <argint>
  argint(2, &minor);
    80005978:	f6840593          	addi	a1,s0,-152
    8000597c:	4509                	li	a0,2
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	270080e7          	jalr	624(ra) # 80002bee <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005986:	08000613          	li	a2,128
    8000598a:	f7040593          	addi	a1,s0,-144
    8000598e:	4501                	li	a0,0
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	29e080e7          	jalr	670(ra) # 80002c2e <argstr>
    80005998:	02054b63          	bltz	a0,800059ce <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000599c:	f6841683          	lh	a3,-152(s0)
    800059a0:	f6c41603          	lh	a2,-148(s0)
    800059a4:	458d                	li	a1,3
    800059a6:	f7040513          	addi	a0,s0,-144
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	77e080e7          	jalr	1918(ra) # 80005128 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b2:	cd11                	beqz	a0,800059ce <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	07e080e7          	jalr	126(ra) # 80003a32 <iunlockput>
  end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	856080e7          	jalr	-1962(ra) # 80004212 <end_op>
  return 0;
    800059c4:	4501                	li	a0,0
}
    800059c6:	60ea                	ld	ra,152(sp)
    800059c8:	644a                	ld	s0,144(sp)
    800059ca:	610d                	addi	sp,sp,160
    800059cc:	8082                	ret
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	844080e7          	jalr	-1980(ra) # 80004212 <end_op>
    return -1;
    800059d6:	557d                	li	a0,-1
    800059d8:	b7fd                	j	800059c6 <sys_mknod+0x6c>

00000000800059da <sys_chdir>:

uint64
sys_chdir(void)
{
    800059da:	7135                	addi	sp,sp,-160
    800059dc:	ed06                	sd	ra,152(sp)
    800059de:	e922                	sd	s0,144(sp)
    800059e0:	e526                	sd	s1,136(sp)
    800059e2:	e14a                	sd	s2,128(sp)
    800059e4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	028080e7          	jalr	40(ra) # 80001a0e <myproc>
    800059ee:	892a                	mv	s2,a0
  
  begin_op();
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	7a2080e7          	jalr	1954(ra) # 80004192 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059f8:	08000613          	li	a2,128
    800059fc:	f6040593          	addi	a1,s0,-160
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	22c080e7          	jalr	556(ra) # 80002c2e <argstr>
    80005a0a:	04054b63          	bltz	a0,80005a60 <sys_chdir+0x86>
    80005a0e:	f6040513          	addi	a0,s0,-160
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	564080e7          	jalr	1380(ra) # 80003f76 <namei>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c131                	beqz	a0,80005a60 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	db2080e7          	jalr	-590(ra) # 800037d0 <ilock>
  if(ip->type != T_DIR){
    80005a26:	04449703          	lh	a4,68(s1)
    80005a2a:	4785                	li	a5,1
    80005a2c:	04f71063          	bne	a4,a5,80005a6c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	e60080e7          	jalr	-416(ra) # 80003892 <iunlock>
  iput(p->cwd);
    80005a3a:	15093503          	ld	a0,336(s2)
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	f4c080e7          	jalr	-180(ra) # 8000398a <iput>
  end_op();
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	7cc080e7          	jalr	1996(ra) # 80004212 <end_op>
  p->cwd = ip;
    80005a4e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a52:	4501                	li	a0,0
}
    80005a54:	60ea                	ld	ra,152(sp)
    80005a56:	644a                	ld	s0,144(sp)
    80005a58:	64aa                	ld	s1,136(sp)
    80005a5a:	690a                	ld	s2,128(sp)
    80005a5c:	610d                	addi	sp,sp,160
    80005a5e:	8082                	ret
    end_op();
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	7b2080e7          	jalr	1970(ra) # 80004212 <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	b7ed                	j	80005a54 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	fc4080e7          	jalr	-60(ra) # 80003a32 <iunlockput>
    end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	79c080e7          	jalr	1948(ra) # 80004212 <end_op>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	bfd1                	j	80005a54 <sys_chdir+0x7a>

0000000080005a82 <sys_exec>:

uint64
sys_exec(void)
{
    80005a82:	7145                	addi	sp,sp,-464
    80005a84:	e786                	sd	ra,456(sp)
    80005a86:	e3a2                	sd	s0,448(sp)
    80005a88:	ff26                	sd	s1,440(sp)
    80005a8a:	fb4a                	sd	s2,432(sp)
    80005a8c:	f74e                	sd	s3,424(sp)
    80005a8e:	f352                	sd	s4,416(sp)
    80005a90:	ef56                	sd	s5,408(sp)
    80005a92:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a94:	e3840593          	addi	a1,s0,-456
    80005a98:	4505                	li	a0,1
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	174080e7          	jalr	372(ra) # 80002c0e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f4040593          	addi	a1,s0,-192
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	182080e7          	jalr	386(ra) # 80002c2e <argstr>
    80005ab4:	87aa                	mv	a5,a0
    return -1;
    80005ab6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab8:	0c07c263          	bltz	a5,80005b7c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005abc:	10000613          	li	a2,256
    80005ac0:	4581                	li	a1,0
    80005ac2:	e4040513          	addi	a0,s0,-448
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	268080e7          	jalr	616(ra) # 80000d2e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ace:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ad2:	89a6                	mv	s3,s1
    80005ad4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ad6:	02000a13          	li	s4,32
    80005ada:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ade:	00391513          	slli	a0,s2,0x3
    80005ae2:	e3040593          	addi	a1,s0,-464
    80005ae6:	e3843783          	ld	a5,-456(s0)
    80005aea:	953e                	add	a0,a0,a5
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	064080e7          	jalr	100(ra) # 80002b50 <fetchaddr>
    80005af4:	02054a63          	bltz	a0,80005b28 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005af8:	e3043783          	ld	a5,-464(s0)
    80005afc:	c3b9                	beqz	a5,80005b42 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	ffc080e7          	jalr	-4(ra) # 80000afa <kalloc>
    80005b06:	85aa                	mv	a1,a0
    80005b08:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b0c:	cd11                	beqz	a0,80005b28 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b0e:	6605                	lui	a2,0x1
    80005b10:	e3043503          	ld	a0,-464(s0)
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	08e080e7          	jalr	142(ra) # 80002ba2 <fetchstr>
    80005b1c:	00054663          	bltz	a0,80005b28 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b20:	0905                	addi	s2,s2,1
    80005b22:	09a1                	addi	s3,s3,8
    80005b24:	fb491be3          	bne	s2,s4,80005ada <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b28:	10048913          	addi	s2,s1,256
    80005b2c:	6088                	ld	a0,0(s1)
    80005b2e:	c531                	beqz	a0,80005b7a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	ece080e7          	jalr	-306(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b38:	04a1                	addi	s1,s1,8
    80005b3a:	ff2499e3          	bne	s1,s2,80005b2c <sys_exec+0xaa>
  return -1;
    80005b3e:	557d                	li	a0,-1
    80005b40:	a835                	j	80005b7c <sys_exec+0xfa>
      argv[i] = 0;
    80005b42:	0a8e                	slli	s5,s5,0x3
    80005b44:	fc040793          	addi	a5,s0,-64
    80005b48:	9abe                	add	s5,s5,a5
    80005b4a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b4e:	e4040593          	addi	a1,s0,-448
    80005b52:	f4040513          	addi	a0,s0,-192
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	190080e7          	jalr	400(ra) # 80004ce6 <exec>
    80005b5e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b60:	10048993          	addi	s3,s1,256
    80005b64:	6088                	ld	a0,0(s1)
    80005b66:	c901                	beqz	a0,80005b76 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	e96080e7          	jalr	-362(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	04a1                	addi	s1,s1,8
    80005b72:	ff3499e3          	bne	s1,s3,80005b64 <sys_exec+0xe2>
  return ret;
    80005b76:	854a                	mv	a0,s2
    80005b78:	a011                	j	80005b7c <sys_exec+0xfa>
  return -1;
    80005b7a:	557d                	li	a0,-1
}
    80005b7c:	60be                	ld	ra,456(sp)
    80005b7e:	641e                	ld	s0,448(sp)
    80005b80:	74fa                	ld	s1,440(sp)
    80005b82:	795a                	ld	s2,432(sp)
    80005b84:	79ba                	ld	s3,424(sp)
    80005b86:	7a1a                	ld	s4,416(sp)
    80005b88:	6afa                	ld	s5,408(sp)
    80005b8a:	6179                	addi	sp,sp,464
    80005b8c:	8082                	ret

0000000080005b8e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b8e:	7139                	addi	sp,sp,-64
    80005b90:	fc06                	sd	ra,56(sp)
    80005b92:	f822                	sd	s0,48(sp)
    80005b94:	f426                	sd	s1,40(sp)
    80005b96:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	e76080e7          	jalr	-394(ra) # 80001a0e <myproc>
    80005ba0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ba2:	fd840593          	addi	a1,s0,-40
    80005ba6:	4501                	li	a0,0
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	066080e7          	jalr	102(ra) # 80002c0e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bb0:	fc840593          	addi	a1,s0,-56
    80005bb4:	fd040513          	addi	a0,s0,-48
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	dd6080e7          	jalr	-554(ra) # 8000498e <pipealloc>
    return -1;
    80005bc0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bc2:	0c054463          	bltz	a0,80005c8a <sys_pipe+0xfc>
  fd0 = -1;
    80005bc6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bca:	fd043503          	ld	a0,-48(s0)
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	518080e7          	jalr	1304(ra) # 800050e6 <fdalloc>
    80005bd6:	fca42223          	sw	a0,-60(s0)
    80005bda:	08054b63          	bltz	a0,80005c70 <sys_pipe+0xe2>
    80005bde:	fc843503          	ld	a0,-56(s0)
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	504080e7          	jalr	1284(ra) # 800050e6 <fdalloc>
    80005bea:	fca42023          	sw	a0,-64(s0)
    80005bee:	06054863          	bltz	a0,80005c5e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf2:	4691                	li	a3,4
    80005bf4:	fc440613          	addi	a2,s0,-60
    80005bf8:	fd843583          	ld	a1,-40(s0)
    80005bfc:	68a8                	ld	a0,80(s1)
    80005bfe:	ffffc097          	auipc	ra,0xffffc
    80005c02:	ace080e7          	jalr	-1330(ra) # 800016cc <copyout>
    80005c06:	02054063          	bltz	a0,80005c26 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c0a:	4691                	li	a3,4
    80005c0c:	fc040613          	addi	a2,s0,-64
    80005c10:	fd843583          	ld	a1,-40(s0)
    80005c14:	0591                	addi	a1,a1,4
    80005c16:	68a8                	ld	a0,80(s1)
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	ab4080e7          	jalr	-1356(ra) # 800016cc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c20:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c22:	06055463          	bgez	a0,80005c8a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c26:	fc442783          	lw	a5,-60(s0)
    80005c2a:	07e9                	addi	a5,a5,26
    80005c2c:	078e                	slli	a5,a5,0x3
    80005c2e:	97a6                	add	a5,a5,s1
    80005c30:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c34:	fc042503          	lw	a0,-64(s0)
    80005c38:	0569                	addi	a0,a0,26
    80005c3a:	050e                	slli	a0,a0,0x3
    80005c3c:	94aa                	add	s1,s1,a0
    80005c3e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c42:	fd043503          	ld	a0,-48(s0)
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	a18080e7          	jalr	-1512(ra) # 8000465e <fileclose>
    fileclose(wf);
    80005c4e:	fc843503          	ld	a0,-56(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	a0c080e7          	jalr	-1524(ra) # 8000465e <fileclose>
    return -1;
    80005c5a:	57fd                	li	a5,-1
    80005c5c:	a03d                	j	80005c8a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c5e:	fc442783          	lw	a5,-60(s0)
    80005c62:	0007c763          	bltz	a5,80005c70 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c66:	07e9                	addi	a5,a5,26
    80005c68:	078e                	slli	a5,a5,0x3
    80005c6a:	94be                	add	s1,s1,a5
    80005c6c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c70:	fd043503          	ld	a0,-48(s0)
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	9ea080e7          	jalr	-1558(ra) # 8000465e <fileclose>
    fileclose(wf);
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	9de080e7          	jalr	-1570(ra) # 8000465e <fileclose>
    return -1;
    80005c88:	57fd                	li	a5,-1
}
    80005c8a:	853e                	mv	a0,a5
    80005c8c:	70e2                	ld	ra,56(sp)
    80005c8e:	7442                	ld	s0,48(sp)
    80005c90:	74a2                	ld	s1,40(sp)
    80005c92:	6121                	addi	sp,sp,64
    80005c94:	8082                	ret
	...

0000000080005ca0 <kernelvec>:
    80005ca0:	7111                	addi	sp,sp,-256
    80005ca2:	e006                	sd	ra,0(sp)
    80005ca4:	e40a                	sd	sp,8(sp)
    80005ca6:	e80e                	sd	gp,16(sp)
    80005ca8:	ec12                	sd	tp,24(sp)
    80005caa:	f016                	sd	t0,32(sp)
    80005cac:	f41a                	sd	t1,40(sp)
    80005cae:	f81e                	sd	t2,48(sp)
    80005cb0:	fc22                	sd	s0,56(sp)
    80005cb2:	e0a6                	sd	s1,64(sp)
    80005cb4:	e4aa                	sd	a0,72(sp)
    80005cb6:	e8ae                	sd	a1,80(sp)
    80005cb8:	ecb2                	sd	a2,88(sp)
    80005cba:	f0b6                	sd	a3,96(sp)
    80005cbc:	f4ba                	sd	a4,104(sp)
    80005cbe:	f8be                	sd	a5,112(sp)
    80005cc0:	fcc2                	sd	a6,120(sp)
    80005cc2:	e146                	sd	a7,128(sp)
    80005cc4:	e54a                	sd	s2,136(sp)
    80005cc6:	e94e                	sd	s3,144(sp)
    80005cc8:	ed52                	sd	s4,152(sp)
    80005cca:	f156                	sd	s5,160(sp)
    80005ccc:	f55a                	sd	s6,168(sp)
    80005cce:	f95e                	sd	s7,176(sp)
    80005cd0:	fd62                	sd	s8,184(sp)
    80005cd2:	e1e6                	sd	s9,192(sp)
    80005cd4:	e5ea                	sd	s10,200(sp)
    80005cd6:	e9ee                	sd	s11,208(sp)
    80005cd8:	edf2                	sd	t3,216(sp)
    80005cda:	f1f6                	sd	t4,224(sp)
    80005cdc:	f5fa                	sd	t5,232(sp)
    80005cde:	f9fe                	sd	t6,240(sp)
    80005ce0:	d3dfc0ef          	jal	ra,80002a1c <kerneltrap>
    80005ce4:	6082                	ld	ra,0(sp)
    80005ce6:	6122                	ld	sp,8(sp)
    80005ce8:	61c2                	ld	gp,16(sp)
    80005cea:	7282                	ld	t0,32(sp)
    80005cec:	7322                	ld	t1,40(sp)
    80005cee:	73c2                	ld	t2,48(sp)
    80005cf0:	7462                	ld	s0,56(sp)
    80005cf2:	6486                	ld	s1,64(sp)
    80005cf4:	6526                	ld	a0,72(sp)
    80005cf6:	65c6                	ld	a1,80(sp)
    80005cf8:	6666                	ld	a2,88(sp)
    80005cfa:	7686                	ld	a3,96(sp)
    80005cfc:	7726                	ld	a4,104(sp)
    80005cfe:	77c6                	ld	a5,112(sp)
    80005d00:	7866                	ld	a6,120(sp)
    80005d02:	688a                	ld	a7,128(sp)
    80005d04:	692a                	ld	s2,136(sp)
    80005d06:	69ca                	ld	s3,144(sp)
    80005d08:	6a6a                	ld	s4,152(sp)
    80005d0a:	7a8a                	ld	s5,160(sp)
    80005d0c:	7b2a                	ld	s6,168(sp)
    80005d0e:	7bca                	ld	s7,176(sp)
    80005d10:	7c6a                	ld	s8,184(sp)
    80005d12:	6c8e                	ld	s9,192(sp)
    80005d14:	6d2e                	ld	s10,200(sp)
    80005d16:	6dce                	ld	s11,208(sp)
    80005d18:	6e6e                	ld	t3,216(sp)
    80005d1a:	7e8e                	ld	t4,224(sp)
    80005d1c:	7f2e                	ld	t5,232(sp)
    80005d1e:	7fce                	ld	t6,240(sp)
    80005d20:	6111                	addi	sp,sp,256
    80005d22:	10200073          	sret
    80005d26:	00000013          	nop
    80005d2a:	00000013          	nop
    80005d2e:	0001                	nop

0000000080005d30 <timervec>:
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	e10c                	sd	a1,0(a0)
    80005d36:	e510                	sd	a2,8(a0)
    80005d38:	e914                	sd	a3,16(a0)
    80005d3a:	6d0c                	ld	a1,24(a0)
    80005d3c:	7110                	ld	a2,32(a0)
    80005d3e:	6194                	ld	a3,0(a1)
    80005d40:	96b2                	add	a3,a3,a2
    80005d42:	e194                	sd	a3,0(a1)
    80005d44:	4589                	li	a1,2
    80005d46:	14459073          	csrw	sip,a1
    80005d4a:	6914                	ld	a3,16(a0)
    80005d4c:	6510                	ld	a2,8(a0)
    80005d4e:	610c                	ld	a1,0(a0)
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	30200073          	mret
	...

0000000080005d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e422                	sd	s0,8(sp)
    80005d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d60:	0c0007b7          	lui	a5,0xc000
    80005d64:	4705                	li	a4,1
    80005d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d68:	c3d8                	sw	a4,4(a5)
}
    80005d6a:	6422                	ld	s0,8(sp)
    80005d6c:	0141                	addi	sp,sp,16
    80005d6e:	8082                	ret

0000000080005d70 <plicinithart>:

void
plicinithart(void)
{
    80005d70:	1141                	addi	sp,sp,-16
    80005d72:	e406                	sd	ra,8(sp)
    80005d74:	e022                	sd	s0,0(sp)
    80005d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c6a080e7          	jalr	-918(ra) # 800019e2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d80:	0085171b          	slliw	a4,a0,0x8
    80005d84:	0c0027b7          	lui	a5,0xc002
    80005d88:	97ba                	add	a5,a5,a4
    80005d8a:	40200713          	li	a4,1026
    80005d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	00052023          	sw	zero,0(a0)
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret

0000000080005da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	c32080e7          	jalr	-974(ra) # 800019e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005db8:	00d5179b          	slliw	a5,a0,0xd
    80005dbc:	0c201537          	lui	a0,0xc201
    80005dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dc2:	4148                	lw	a0,4(a0)
    80005dc4:	60a2                	ld	ra,8(sp)
    80005dc6:	6402                	ld	s0,0(sp)
    80005dc8:	0141                	addi	sp,sp,16
    80005dca:	8082                	ret

0000000080005dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	1000                	addi	s0,sp,32
    80005dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	c0a080e7          	jalr	-1014(ra) # 800019e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005de0:	00d5151b          	slliw	a0,a0,0xd
    80005de4:	0c2017b7          	lui	a5,0xc201
    80005de8:	97aa                	add	a5,a5,a0
    80005dea:	c3c4                	sw	s1,4(a5)
}
    80005dec:	60e2                	ld	ra,24(sp)
    80005dee:	6442                	ld	s0,16(sp)
    80005df0:	64a2                	ld	s1,8(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005df6:	1141                	addi	sp,sp,-16
    80005df8:	e406                	sd	ra,8(sp)
    80005dfa:	e022                	sd	s0,0(sp)
    80005dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dfe:	479d                	li	a5,7
    80005e00:	04a7cc63          	blt	a5,a0,80005e58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e04:	0001c797          	auipc	a5,0x1c
    80005e08:	02c78793          	addi	a5,a5,44 # 80021e30 <disk>
    80005e0c:	97aa                	add	a5,a5,a0
    80005e0e:	0187c783          	lbu	a5,24(a5)
    80005e12:	ebb9                	bnez	a5,80005e68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e14:	00451613          	slli	a2,a0,0x4
    80005e18:	0001c797          	auipc	a5,0x1c
    80005e1c:	01878793          	addi	a5,a5,24 # 80021e30 <disk>
    80005e20:	6394                	ld	a3,0(a5)
    80005e22:	96b2                	add	a3,a3,a2
    80005e24:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e28:	6398                	ld	a4,0(a5)
    80005e2a:	9732                	add	a4,a4,a2
    80005e2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e38:	953e                	add	a0,a0,a5
    80005e3a:	4785                	li	a5,1
    80005e3c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e40:	0001c517          	auipc	a0,0x1c
    80005e44:	00850513          	addi	a0,a0,8 # 80021e48 <disk+0x18>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	2d2080e7          	jalr	722(ra) # 8000211a <wakeup>
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret
    panic("free_desc 1");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	8f850513          	addi	a0,a0,-1800 # 80008750 <syscalls+0x300>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e4080e7          	jalr	1764(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	8f850513          	addi	a0,a0,-1800 # 80008760 <syscalls+0x310>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d4080e7          	jalr	1748(ra) # 80000544 <panic>

0000000080005e78 <virtio_disk_init>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	e04a                	sd	s2,0(sp)
    80005e82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e84:	00003597          	auipc	a1,0x3
    80005e88:	8ec58593          	addi	a1,a1,-1812 # 80008770 <syscalls+0x320>
    80005e8c:	0001c517          	auipc	a0,0x1c
    80005e90:	0cc50513          	addi	a0,a0,204 # 80021f58 <disk+0x128>
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	d0e080e7          	jalr	-754(ra) # 80000ba2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	4398                	lw	a4,0(a5)
    80005ea2:	2701                	sext.w	a4,a4
    80005ea4:	747277b7          	lui	a5,0x74727
    80005ea8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eac:	14f71e63          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb0:	100017b7          	lui	a5,0x10001
    80005eb4:	43dc                	lw	a5,4(a5)
    80005eb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb8:	4709                	li	a4,2
    80005eba:	14e79763          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	479c                	lw	a5,8(a5)
    80005ec4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec6:	14e79163          	bne	a5,a4,80006008 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	47d8                	lw	a4,12(a5)
    80005ed0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ed2:	554d47b7          	lui	a5,0x554d4
    80005ed6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eda:	12f71763          	bne	a4,a5,80006008 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee6:	4705                	li	a4,1
    80005ee8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eea:	470d                	li	a4,3
    80005eec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ef0:	c7ffe737          	lui	a4,0xc7ffe
    80005ef4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7ef>
    80005ef8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	472d                	li	a4,11
    80005f00:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f02:	0707a903          	lw	s2,112(a5)
    80005f06:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f08:	00897793          	andi	a5,s2,8
    80005f0c:	10078663          	beqz	a5,80006018 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f18:	43fc                	lw	a5,68(a5)
    80005f1a:	2781                	sext.w	a5,a5
    80005f1c:	10079663          	bnez	a5,80006028 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f20:	100017b7          	lui	a5,0x10001
    80005f24:	5bdc                	lw	a5,52(a5)
    80005f26:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f28:	10078863          	beqz	a5,80006038 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f2c:	471d                	li	a4,7
    80005f2e:	10f77d63          	bgeu	a4,a5,80006048 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	bc8080e7          	jalr	-1080(ra) # 80000afa <kalloc>
    80005f3a:	0001c497          	auipc	s1,0x1c
    80005f3e:	ef648493          	addi	s1,s1,-266 # 80021e30 <disk>
    80005f42:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	bb6080e7          	jalr	-1098(ra) # 80000afa <kalloc>
    80005f4c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	bac080e7          	jalr	-1108(ra) # 80000afa <kalloc>
    80005f56:	87aa                	mv	a5,a0
    80005f58:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	cd75                	beqz	a0,80006058 <virtio_disk_init+0x1e0>
    80005f5e:	0001c717          	auipc	a4,0x1c
    80005f62:	eda73703          	ld	a4,-294(a4) # 80021e38 <disk+0x8>
    80005f66:	cb6d                	beqz	a4,80006058 <virtio_disk_init+0x1e0>
    80005f68:	cbe5                	beqz	a5,80006058 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	dc0080e7          	jalr	-576(ra) # 80000d2e <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f76:	0001c497          	auipc	s1,0x1c
    80005f7a:	eba48493          	addi	s1,s1,-326 # 80021e30 <disk>
    80005f7e:	6605                	lui	a2,0x1
    80005f80:	4581                	li	a1,0
    80005f82:	6488                	ld	a0,8(s1)
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	daa080e7          	jalr	-598(ra) # 80000d2e <memset>
  memset(disk.used, 0, PGSIZE);
    80005f8c:	6605                	lui	a2,0x1
    80005f8e:	4581                	li	a1,0
    80005f90:	6888                	ld	a0,16(s1)
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	d9c080e7          	jalr	-612(ra) # 80000d2e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f9a:	100017b7          	lui	a5,0x10001
    80005f9e:	4721                	li	a4,8
    80005fa0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fa2:	4098                	lw	a4,0(s1)
    80005fa4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fa8:	40d8                	lw	a4,4(s1)
    80005faa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fae:	6498                	ld	a4,8(s1)
    80005fb0:	0007069b          	sext.w	a3,a4
    80005fb4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fb8:	9701                	srai	a4,a4,0x20
    80005fba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fbe:	6898                	ld	a4,16(s1)
    80005fc0:	0007069b          	sext.w	a3,a4
    80005fc4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fc8:	9701                	srai	a4,a4,0x20
    80005fca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fce:	4685                	li	a3,1
    80005fd0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005fd2:	4705                	li	a4,1
    80005fd4:	00d48c23          	sb	a3,24(s1)
    80005fd8:	00e48ca3          	sb	a4,25(s1)
    80005fdc:	00e48d23          	sb	a4,26(s1)
    80005fe0:	00e48da3          	sb	a4,27(s1)
    80005fe4:	00e48e23          	sb	a4,28(s1)
    80005fe8:	00e48ea3          	sb	a4,29(s1)
    80005fec:	00e48f23          	sb	a4,30(s1)
    80005ff0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ff4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff8:	0727a823          	sw	s2,112(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6902                	ld	s2,0(sp)
    80006004:	6105                	addi	sp,sp,32
    80006006:	8082                	ret
    panic("could not find virtio disk");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	77850513          	addi	a0,a0,1912 # 80008780 <syscalls+0x330>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006018:	00002517          	auipc	a0,0x2
    8000601c:	78850513          	addi	a0,a0,1928 # 800087a0 <syscalls+0x350>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	79850513          	addi	a0,a0,1944 # 800087c0 <syscalls+0x370>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	7a850513          	addi	a0,a0,1960 # 800087e0 <syscalls+0x390>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	7b850513          	addi	a0,a0,1976 # 80008800 <syscalls+0x3b0>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	7c850513          	addi	a0,a0,1992 # 80008820 <syscalls+0x3d0>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>

0000000080006068 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006068:	7159                	addi	sp,sp,-112
    8000606a:	f486                	sd	ra,104(sp)
    8000606c:	f0a2                	sd	s0,96(sp)
    8000606e:	eca6                	sd	s1,88(sp)
    80006070:	e8ca                	sd	s2,80(sp)
    80006072:	e4ce                	sd	s3,72(sp)
    80006074:	e0d2                	sd	s4,64(sp)
    80006076:	fc56                	sd	s5,56(sp)
    80006078:	f85a                	sd	s6,48(sp)
    8000607a:	f45e                	sd	s7,40(sp)
    8000607c:	f062                	sd	s8,32(sp)
    8000607e:	ec66                	sd	s9,24(sp)
    80006080:	e86a                	sd	s10,16(sp)
    80006082:	1880                	addi	s0,sp,112
    80006084:	892a                	mv	s2,a0
    80006086:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006088:	00c52c83          	lw	s9,12(a0)
    8000608c:	001c9c9b          	slliw	s9,s9,0x1
    80006090:	1c82                	slli	s9,s9,0x20
    80006092:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006096:	0001c517          	auipc	a0,0x1c
    8000609a:	ec250513          	addi	a0,a0,-318 # 80021f58 <disk+0x128>
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	b94080e7          	jalr	-1132(ra) # 80000c32 <acquire>
  for(int i = 0; i < 3; i++){
    800060a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800060aa:	0001cb17          	auipc	s6,0x1c
    800060ae:	d86b0b13          	addi	s6,s6,-634 # 80021e30 <disk>
  for(int i = 0; i < 3; i++){
    800060b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b6:	0001cc17          	auipc	s8,0x1c
    800060ba:	ea2c0c13          	addi	s8,s8,-350 # 80021f58 <disk+0x128>
    800060be:	a8b5                	j	8000613a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060c0:	00fb06b3          	add	a3,s6,a5
    800060c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ca:	0207c563          	bltz	a5,800060f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ce:	2485                	addiw	s1,s1,1
    800060d0:	0711                	addi	a4,a4,4
    800060d2:	1f548a63          	beq	s1,s5,800062c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d8:	0001c697          	auipc	a3,0x1c
    800060dc:	d5868693          	addi	a3,a3,-680 # 80021e30 <disk>
    800060e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060e2:	0186c583          	lbu	a1,24(a3)
    800060e6:	fde9                	bnez	a1,800060c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060e8:	2785                	addiw	a5,a5,1
    800060ea:	0685                	addi	a3,a3,1
    800060ec:	ff779be3          	bne	a5,s7,800060e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060f0:	57fd                	li	a5,-1
    800060f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060f4:	02905a63          	blez	s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060f8:	f9042503          	lw	a0,-112(s0)
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	cfa080e7          	jalr	-774(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006104:	4785                	li	a5,1
    80006106:	0297d163          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000610a:	f9442503          	lw	a0,-108(s0)
    8000610e:	00000097          	auipc	ra,0x0
    80006112:	ce8080e7          	jalr	-792(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006116:	4789                	li	a5,2
    80006118:	0097d863          	bge	a5,s1,80006128 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000611c:	f9842503          	lw	a0,-104(s0)
    80006120:	00000097          	auipc	ra,0x0
    80006124:	cd6080e7          	jalr	-810(ra) # 80005df6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006128:	85e2                	mv	a1,s8
    8000612a:	0001c517          	auipc	a0,0x1c
    8000612e:	d1e50513          	addi	a0,a0,-738 # 80021e48 <disk+0x18>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	f84080e7          	jalr	-124(ra) # 800020b6 <sleep>
  for(int i = 0; i < 3; i++){
    8000613a:	f9040713          	addi	a4,s0,-112
    8000613e:	84ce                	mv	s1,s3
    80006140:	bf59                	j	800060d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006142:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006146:	00479693          	slli	a3,a5,0x4
    8000614a:	0001c797          	auipc	a5,0x1c
    8000614e:	ce678793          	addi	a5,a5,-794 # 80021e30 <disk>
    80006152:	97b6                	add	a5,a5,a3
    80006154:	4685                	li	a3,1
    80006156:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006158:	0001c597          	auipc	a1,0x1c
    8000615c:	cd858593          	addi	a1,a1,-808 # 80021e30 <disk>
    80006160:	00a60793          	addi	a5,a2,10
    80006164:	0792                	slli	a5,a5,0x4
    80006166:	97ae                	add	a5,a5,a1
    80006168:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000616c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006170:	f6070693          	addi	a3,a4,-160
    80006174:	619c                	ld	a5,0(a1)
    80006176:	97b6                	add	a5,a5,a3
    80006178:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000617a:	6188                	ld	a0,0(a1)
    8000617c:	96aa                	add	a3,a3,a0
    8000617e:	47c1                	li	a5,16
    80006180:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006182:	4785                	li	a5,1
    80006184:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006188:	f9442783          	lw	a5,-108(s0)
    8000618c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006190:	0792                	slli	a5,a5,0x4
    80006192:	953e                	add	a0,a0,a5
    80006194:	05890693          	addi	a3,s2,88
    80006198:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000619a:	6188                	ld	a0,0(a1)
    8000619c:	97aa                	add	a5,a5,a0
    8000619e:	40000693          	li	a3,1024
    800061a2:	c794                	sw	a3,8(a5)
  if(write)
    800061a4:	100d0d63          	beqz	s10,800062be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ac:	00c7d683          	lhu	a3,12(a5)
    800061b0:	0016e693          	ori	a3,a3,1
    800061b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061b8:	f9842583          	lw	a1,-104(s0)
    800061bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c0:	0001c697          	auipc	a3,0x1c
    800061c4:	c7068693          	addi	a3,a3,-912 # 80021e30 <disk>
    800061c8:	00260793          	addi	a5,a2,2
    800061cc:	0792                	slli	a5,a5,0x4
    800061ce:	97b6                	add	a5,a5,a3
    800061d0:	587d                	li	a6,-1
    800061d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	0592                	slli	a1,a1,0x4
    800061d8:	952e                	add	a0,a0,a1
    800061da:	f9070713          	addi	a4,a4,-112
    800061de:	9736                	add	a4,a4,a3
    800061e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061e2:	6298                	ld	a4,0(a3)
    800061e4:	972e                	add	a4,a4,a1
    800061e6:	4585                	li	a1,1
    800061e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ea:	4509                	li	a0,2
    800061ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061fc:	6698                	ld	a4,8(a3)
    800061fe:	00275783          	lhu	a5,2(a4)
    80006202:	8b9d                	andi	a5,a5,7
    80006204:	0786                	slli	a5,a5,0x1
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000620c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006210:	6698                	ld	a4,8(a3)
    80006212:	00275783          	lhu	a5,2(a4)
    80006216:	2785                	addiw	a5,a5,1
    80006218:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000621c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006220:	100017b7          	lui	a5,0x10001
    80006224:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006228:	00492703          	lw	a4,4(s2)
    8000622c:	4785                	li	a5,1
    8000622e:	02f71163          	bne	a4,a5,80006250 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006232:	0001c997          	auipc	s3,0x1c
    80006236:	d2698993          	addi	s3,s3,-730 # 80021f58 <disk+0x128>
  while(b->disk == 1) {
    8000623a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000623c:	85ce                	mv	a1,s3
    8000623e:	854a                	mv	a0,s2
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	e76080e7          	jalr	-394(ra) # 800020b6 <sleep>
  while(b->disk == 1) {
    80006248:	00492783          	lw	a5,4(s2)
    8000624c:	fe9788e3          	beq	a5,s1,8000623c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006250:	f9042903          	lw	s2,-112(s0)
    80006254:	00290793          	addi	a5,s2,2
    80006258:	00479713          	slli	a4,a5,0x4
    8000625c:	0001c797          	auipc	a5,0x1c
    80006260:	bd478793          	addi	a5,a5,-1068 # 80021e30 <disk>
    80006264:	97ba                	add	a5,a5,a4
    80006266:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000626a:	0001c997          	auipc	s3,0x1c
    8000626e:	bc698993          	addi	s3,s3,-1082 # 80021e30 <disk>
    80006272:	00491713          	slli	a4,s2,0x4
    80006276:	0009b783          	ld	a5,0(s3)
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006280:	854a                	mv	a0,s2
    80006282:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006286:	00000097          	auipc	ra,0x0
    8000628a:	b70080e7          	jalr	-1168(ra) # 80005df6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000628e:	8885                	andi	s1,s1,1
    80006290:	f0ed                	bnez	s1,80006272 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006292:	0001c517          	auipc	a0,0x1c
    80006296:	cc650513          	addi	a0,a0,-826 # 80021f58 <disk+0x128>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	a4c080e7          	jalr	-1460(ra) # 80000ce6 <release>
}
    800062a2:	70a6                	ld	ra,104(sp)
    800062a4:	7406                	ld	s0,96(sp)
    800062a6:	64e6                	ld	s1,88(sp)
    800062a8:	6946                	ld	s2,80(sp)
    800062aa:	69a6                	ld	s3,72(sp)
    800062ac:	6a06                	ld	s4,64(sp)
    800062ae:	7ae2                	ld	s5,56(sp)
    800062b0:	7b42                	ld	s6,48(sp)
    800062b2:	7ba2                	ld	s7,40(sp)
    800062b4:	7c02                	ld	s8,32(sp)
    800062b6:	6ce2                	ld	s9,24(sp)
    800062b8:	6d42                	ld	s10,16(sp)
    800062ba:	6165                	addi	sp,sp,112
    800062bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062be:	4689                	li	a3,2
    800062c0:	00d79623          	sh	a3,12(a5)
    800062c4:	b5e5                	j	800061ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c6:	f9042603          	lw	a2,-112(s0)
    800062ca:	00a60713          	addi	a4,a2,10
    800062ce:	0712                	slli	a4,a4,0x4
    800062d0:	0001c517          	auipc	a0,0x1c
    800062d4:	b6850513          	addi	a0,a0,-1176 # 80021e38 <disk+0x8>
    800062d8:	953a                	add	a0,a0,a4
  if(write)
    800062da:	e60d14e3          	bnez	s10,80006142 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062de:	00a60793          	addi	a5,a2,10
    800062e2:	00479693          	slli	a3,a5,0x4
    800062e6:	0001c797          	auipc	a5,0x1c
    800062ea:	b4a78793          	addi	a5,a5,-1206 # 80021e30 <disk>
    800062ee:	97b6                	add	a5,a5,a3
    800062f0:	0007a423          	sw	zero,8(a5)
    800062f4:	b595                	j	80006158 <virtio_disk_rw+0xf0>

00000000800062f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062f6:	1101                	addi	sp,sp,-32
    800062f8:	ec06                	sd	ra,24(sp)
    800062fa:	e822                	sd	s0,16(sp)
    800062fc:	e426                	sd	s1,8(sp)
    800062fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006300:	0001c497          	auipc	s1,0x1c
    80006304:	b3048493          	addi	s1,s1,-1232 # 80021e30 <disk>
    80006308:	0001c517          	auipc	a0,0x1c
    8000630c:	c5050513          	addi	a0,a0,-944 # 80021f58 <disk+0x128>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	922080e7          	jalr	-1758(ra) # 80000c32 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006318:	10001737          	lui	a4,0x10001
    8000631c:	533c                	lw	a5,96(a4)
    8000631e:	8b8d                	andi	a5,a5,3
    80006320:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006322:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006326:	689c                	ld	a5,16(s1)
    80006328:	0204d703          	lhu	a4,32(s1)
    8000632c:	0027d783          	lhu	a5,2(a5)
    80006330:	04f70863          	beq	a4,a5,80006380 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006334:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006338:	6898                	ld	a4,16(s1)
    8000633a:	0204d783          	lhu	a5,32(s1)
    8000633e:	8b9d                	andi	a5,a5,7
    80006340:	078e                	slli	a5,a5,0x3
    80006342:	97ba                	add	a5,a5,a4
    80006344:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006346:	00278713          	addi	a4,a5,2
    8000634a:	0712                	slli	a4,a4,0x4
    8000634c:	9726                	add	a4,a4,s1
    8000634e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006352:	e721                	bnez	a4,8000639a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006354:	0789                	addi	a5,a5,2
    80006356:	0792                	slli	a5,a5,0x4
    80006358:	97a6                	add	a5,a5,s1
    8000635a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000635c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006360:	ffffc097          	auipc	ra,0xffffc
    80006364:	dba080e7          	jalr	-582(ra) # 8000211a <wakeup>

    disk.used_idx += 1;
    80006368:	0204d783          	lhu	a5,32(s1)
    8000636c:	2785                	addiw	a5,a5,1
    8000636e:	17c2                	slli	a5,a5,0x30
    80006370:	93c1                	srli	a5,a5,0x30
    80006372:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006376:	6898                	ld	a4,16(s1)
    80006378:	00275703          	lhu	a4,2(a4)
    8000637c:	faf71ce3          	bne	a4,a5,80006334 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006380:	0001c517          	auipc	a0,0x1c
    80006384:	bd850513          	addi	a0,a0,-1064 # 80021f58 <disk+0x128>
    80006388:	ffffb097          	auipc	ra,0xffffb
    8000638c:	95e080e7          	jalr	-1698(ra) # 80000ce6 <release>
}
    80006390:	60e2                	ld	ra,24(sp)
    80006392:	6442                	ld	s0,16(sp)
    80006394:	64a2                	ld	s1,8(sp)
    80006396:	6105                	addi	sp,sp,32
    80006398:	8082                	ret
      panic("virtio_disk_intr status");
    8000639a:	00002517          	auipc	a0,0x2
    8000639e:	49e50513          	addi	a0,a0,1182 # 80008838 <syscalls+0x3e8>
    800063a2:	ffffa097          	auipc	ra,0xffffa
    800063a6:	1a2080e7          	jalr	418(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
