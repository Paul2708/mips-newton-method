#
# Karlsruher Institut fuer Technologie
# Institut fuer Technische Informatik (ITEC) 
# Vorlesung Rechnerorganisation
# 
# Autor(en): 		Paul Hoger
# Matrikelnummer:	-/-
# Tutoriumsnummer:	-/-
# Name des Tutors:	-/-
#


        .data
        # space for the polynomials
                        .align 3
polynomial:             .space 40       # conventions: starting with a0 to a4                   
derivedPoly:            .space 40       # for a0 + a1*x + a2*x^2 + a3*x^3 + a4*x^4
        # the polynomial for which you have to find the null points for the given start values below
testPoly:               .double 2, -0.5, -2.2, 0.0, 0.25

        # algorithm values
maxRounds:              .word 30
epsilon:                .double 0.00001
# - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! -
# write your found solutions for given start values here
x0:                     .double -5.1    # found solution: -2.6216761331927914
x1:                     .double -0.8    # found solution: -1.1837432144601066
x2:                     .double 1       # found solution: 0.8816934297400127
x3:                     .double 3.5     # found solution: 2.923728494996961

        # help values
null:                   .double 0
eins:                   .double 1

        # strings 
readFactorsPrompt:      .asciiz "Please insert polynomial factors for polynomial a0 + a1*x + a2*x^2 + a3*x^3 + a4*x^4."
readNextFactor:         .asciiz "\nnext factor: "
newLine:                .asciiz "\n"
startValue:             .asciiz "\nStart newton's method with start value: "
noSolutionFound:        .asciiz "Did not converge. No solution found."
solutionFound:          .asciiz "The found solution is: "
polyPrint:              .asciiz "\nPolynomial factors: "
comma:          .asciiz ", "
 
        .text
        .globl main
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#       MAIN            MAIN            MAIN            MAIN            MAIN            #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
main:           jal alignStackPointer   # align stackpointer to multiple of 8
        # to read in a polynomial uncomment the polynomial lines and comment those with test polynomial
                #la $a0, polynomial
                #jal readFactors
                
        # print the polynomial
                #la $a0, polynomial
                la $a0, testPoly
                jal printPolynomial
                
        # first we need to compute the derived polynomial, since we need it in the algorithm
                #la $a0, polynomial
                la $a0, testPoly
                la $a1, derivedPoly
                jal derive                      # - ! - implement this subroutine               
        # print the derived polynomial to see whether it was computed correctly
                #la $a0, polynomial
                la $a0, derivedPoly
                jal printPolynomial
                                
        # now we can run the newton subroutine with our start values                    
                la $a2, x0
                #la $a0, polynomial
                la $a0, testPoly
                la $a1, derivedPoly
                jal newtonsMethod               # - ! - implement this subroutine
                
                la $a2, x1
                #la $a0, polynomial
                la $a0, testPoly
                la $a1, derivedPoly
                jal newtonsMethod
                
                la $a2, x2
                #la $a0, polynomial
                la $a0, testPoly
                la $a1, derivedPoly
                jal newtonsMethod
                
                la $a2, x3
                #la $a0, polynomial
                la $a0, testPoly
                la $a1, derivedPoly
                jal newtonsMethod
                                
                li $v0, 10
                syscall

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Subroutine: newtonsMethod                                                             #
#       The subroutine runs newton's method for given polynomial f and start value.     #
#                                                                                       #
# Parameters:                                                                           #
#       $a0 - address of polynomial f                                                   #
#       $a1 - address of derived polynomial f'                                          #
#       $a2 - address of x_0, start value for algorithm                                 #
# Output:                                                                               #
#       $f0 - the solution of the algorithm, null point of given polynomial (hopefully) #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
newtonsMethod:          # prepare a new stackframe for the subroutine
                subu $sp, $sp, 24
                sw $s0, 20($sp)
                sw $s1, 16($sp)
                sw $s2, 12($sp)
                sw $ra, 8($sp)
                sw $fp, 4($sp)
                addu $fp, $sp, 24

                # store arguments in caller-save registers
                move $s0, $a0           
                move $s1, $a1
                move $s2, $a2

                # possible register use: 
                # s0 = &f, s1 = &f', s2 = &x0
                # f0 = x_n, f2= f(x_n), f4 = f'(x_n), $s3 = n, $s4 = maxRounds
                l.d $f0, ($s2)          # load x_0 in $f0
                # print start value
                la $a0, startValue
                jal printString
                mov.d $f12, $f0
                jal printDouble
                la $a0, newLine
                jal printString
                
# - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! -
        	
        	# Prepare variables
        	li $s3, 0		# $s3  = Round counter
        	lw $s4, maxRounds	# $s4 = Max rounds
        	l.d $f14, epsilon  	# $f14 = epsilon
        	
        	l.d $f16, ($s2) 	# $f16 = n = x0
        	
       while:  	
       		# Calculate |f(x_n)|
       		move $a0, $s0
       		mov.d $f0, $f16
        	jal evaluatePolynomial
        	mov.d $f18, $f12	# $f18 = f(n)
        	abs.d $f10, $f12	# $f10 = |f(n)|
       
       		# Check if |f(x_n)| < epsilon
       		c.le.d $f10, $f14
        	bc1t return
        	
        	# Calculate f'(x_n)
        	move $a0, $s1
        	mov.d $f0, $f16
        	jal evaluatePolynomial
        	mov.d $f20, $f12	# $f20 = f'(n)
        	
        	# Calculate n+1
        	div.d $f8, $f18, $f20
        	sub.d $f16, $f16, $f8	
        	
        	# Check rounds
        	addi $s3, $s3, 1
        	bge $s3, $s4, not_found
        	
        	# Jump back
        	j while
   
        	# No sulution was found     		
   not_found:	la $a0, noSolutionFound	
   		jal printString
   		j end
      
      		# Return the solution
      return:  la $a0, solutionFound
      		jal printString
      		mov.d $f12, $f16
      		jal printDouble
	 end:
	 
# - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - 
                # restore the old stackframe and return to the calling function
                lw $s0, 20($sp)
                lw $s1, 16($sp)
                lw $s2, 12($sp)
                lw $ra, 8($sp)
                lw $fp, 4($sp)
                addu $sp, $sp, 24
                jr $ra
                
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Subroutine: evaluatePolynomial                                                        #                                                                       #
#       The subroutine evaluates the polynomial on the given x coordinate.              #
#                                                                                       #
# Parameters:                                                                           #
#       $a0 - start address of polynomial factors                                       #
#       $f0 - value x at which polynomial will be evaluated                             #
# Output:                                                                               #
#       $f12 - the computed value                                                       #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
evaluatePolynomial: 
                # prepare a new stackframe for the subroutine
                subu $sp, $sp, 48
                s.d $f0, 48($sp)        # to make it easier for newton method
                s.d $f2, 40($sp)        # we store the floating point registers
                s.d $f4, 32($sp)        # to restore it after the evaluation
                s.d $f6, 24($sp)
                s.d $f8, 16($sp)
                sw $ra, 8($sp)
                sw $fp, 4($sp)
                addu $fp, $sp, 48

# - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! -
        	
		l.d $f12, null 		# Result sum
    
        	li $t0, 0 		# Loop counter
        	
   eval_loop:	bge $t0, 5, eval_done
        	
        	# Get array entry
        	mul $t1, $t0, 8
        	addu $t2, $a0, $t1
        	l.d $f4, 0($t2)		# $f4 = a[i]
        	
        	# Get power
    	  	l.d $f6, eins
      		li $t1, 0
    pow_loop:  	bge $t1, $t0, multiply
        	mul.d $f6, $f6, $f0	# $f6 = x^i
        	
        	addi $t1, $t1, 1
        	j pow_loop
        	
        	# Multiply and sum up
    multiply:	mul.d $f8, $f4, $f6
    		add.d $f12, $f12, $f8 
    		
    		addi $t0, $t0, 1
        	j eval_loop
        
   eval_done:
                 
# - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ -                 
                # restore the old stackframe and return to the calling function
                l.d $f0, 48($sp)        
                l.d $f2, 40($sp)        # note that this restores the floating point registers
                l.d $f4, 32($sp)        # f0 - f9
                l.d $f6, 24($sp)        # return value has to be stored in f12
                l.d $f8, 16($sp)
                lw $ra, 8($sp)
                lw $fp, 4($sp)
                addu $sp, $sp, 48
                jr $ra            

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Subroutine: derive                                                                    #                                                                       #
#       The subroutine derives the polynomial of degree 4 at $a0.                       #
#       Stores the derived polynomial at $a1.                                           #
#                                                                                       #
# Parameters:                                                                           #
#       $a0 - address of polynomial f                                                   #
#       $a1 - address where the derived polynomial f' will be stored                    #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
derive: 
                # prepare a new stackframe for the subroutine
                subu $sp, $sp, 8
                sw $ra, 8($sp)
                sw $fp, 4($sp)
                addu $fp, $sp, 8
# - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! - ! -
        	
        	li $t0, 1 		# Loop counter
        	
 derive_loop:	bge $t0, 5, derive_done
        	
        	# Get array entry
        	mul $t1, $t0, 8
        	addu $t2, $a0, $t1
        	l.d $f0, 0($t2)		# $f0 = a[i]
        	
        	# Convert i to double
        	mtc1.d $t0, $f2
        	cvt.d.w $f2, $f2	# $f2 = i
        	
        	mul.d $f4, $f2, $f0
        	
        	# Store derivation
        	subi $t1, $t0, 1
        	mul $t1, $t1, 8
        	addu $t2, $a1, $t1
    		s.d $f4, 0($t2)
    		
    		addi $t0, $t0, 1
        	j derive_loop
        
 derive_done:

# - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - ^ - 
 
                # restore the old stackframe and return to the calling function
                lw $ra, 8($sp)
                lw $fp, 4($sp)
                addu $sp, $sp, 8
                jr $ra
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Subroutine: readFactors                                                               #
#       The subroutine asks for the polynomial factors and stores them at given address.#
#                                                                                       #
# Parameters:                                                                           #
#       $a0 - start address of where to store the factors                               #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
readFactors: 
                # prepare a new stackframe for the subroutine
                subu $sp, $sp, 8
                sw $ra, 8($sp)
                sw $fp, 4($sp)
                addu $fp, $sp, 8
                
                move $s0, $a0
                la $a0, readFactorsPrompt
                jal printString
                        
        # for (i = 0; i <= 4; i++) {
        #    a[i] =  readDouble 
        # }
                li $s1, 4               # 4
                li $s2, 0               # i = 0
        loopR:  bgt $s2, $s1, outR      # i > 4 ? out : go on
                
                la $a0, readNextFactor
                jal printString
                
                mul $t3, $s2, 8         # i * 8 since we handle double
                add $a0, $t3, $s0       # &a[i]
                jal readAndStoreDouble
                
                addi $s2, $s2, 1        # i++
                j loopR
        outR:           

                # restore the old stackframe and return to the calling function
                lw $ra, 8($sp)
                lw $fp, 4($sp)
                addu $sp, $sp, 8
                jr $ra
                
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Subroutine: printPolynomial                                                           #                                                                       #
#       The subroutine prints the factors of the polynomial given in $a0.               #
#                                                                                       #
# Parameters:                                                                           #
#       $a0 - start address of polynomial factors                                       #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
printPolynomial:
                # prepare a new stackframe for the subroutine
                subu $sp, $sp, 20
                sw $s0, 20($sp)
                sw $s1, 16($sp)
                sw $s2, 12($sp)
                sw $ra, 8($sp)
                sw $fp, 4($sp)
                addu $fp, $sp, 20
                
                move $s0, $a0           # save poly start address
                
                la $a0, polyPrint       # print polynomial string
                jal printString
                
                li $s1, 4               # 4
                li $s2, 0               # i = 0
        ploop:  
                mul $t3, $s2, 8         # i * 8 since we handle double
                add $t3, $t3, $s0       # &a[i]
                l.d $f12, 0($t3)                # a[i]
                jal printDouble
                
                beq $s2, $s1, pout      # i = 4 ? out : go on   to not print comma
                la $a0, comma           # print comma
                jal printString
                
                addi $s2, $s2, 1        # i++
                ble $s2, $s1, ploop     # i <= 4 ? loop : go on
                
        pout:   # restore the old stackframe and return to the calling function
                lw $s0, 20($sp)
                lw $s1, 16($sp)
                lw $s2, 12($sp)
                lw $ra, 8($sp)
                lw $fp, 4($sp)
                addu $sp, $sp, 20
                jr $ra

# - - some more little helping subroutines  - - - - - - - - - - - - - - - - - - - - - - #
# prints string with start address in $a0
printString:    li $v0, 4
                syscall
                jr $ra
                
# prints double at $f12
printDouble:    li $v0, 3
                syscall
                jr $ra

# reads double and stores it at $a0     
readAndStoreDouble:
                li $v0, 7
                syscall
                s.d $f0, 0($a0)
                jr $ra

# aligns stack pointer to multiple of 8
alignStackPointer:
                li $t0, 8
                div $sp, $t0
                mfhi $t0
                sub $sp, $sp, $t0
                jr $ra
