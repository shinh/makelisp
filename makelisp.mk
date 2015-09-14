digits_:=0_1_2_3_4_5_6_7_8_9
digits:=0 1 2 3 4 5 6 7 8 9
sub_digits:=1 2 3 4 5 6 7 8 9
op:=(
cp:=)
sp:=$(subst x, ,x)

define tail
$(wordlist 2,$(words $1),$1)
endef

define rep
$(wordlist 1,$(or $1,0),$(digits))
endef

define add1
$(words $(call rep,$1) $(call rep,$2) $(call rep,$3))
endef

define sub1_impl3
$(words $(wordlist 2,99,$1))
endef

define sub1_impl2
$(if $2,$(call sub1_impl3,$2),$(words $(wordlist $(call sub1_impl3,$1),99,$(sub_digits))) 1)
endef

define sub1_impl
$(call sub1_impl2,$(wordlist $1,$2,$(digits)),$(wordlist $2,$1,$(digits)))
endef

define sub1
$(call sub1_impl,$(if $1,$(words $(call rep,$1) x),1),$(if $2,$(words $(call rep,$2) x $3),$(if $3,2,1)))
endef

define num_last
$(firstword $(foreach i,$(digits),$(if $(filter %$i,$1),$i)))
endef

define num_prefix
$(firstword $(foreach i,$(digits),$(if $(filter %$i,$1),$(patsubst %$i,%,$1))))
endef

define num_split
$(if $1,$(call num_split_inv,$(call num_prefix,$1)) $(call num_last,$1))
endef

define num_split_inv
$(if $1,$(call num_last,$1) $(call num_split_inv,$(call num_prefix,$1)))
endef

define join_inv
$(if $1,$(call join_inv,$(wordlist 2,99,$1))$(firstword $1))
endef

define add_impl2
$(call add_impl,$2,$3,$(word 2,$1))$(firstword $1)
endef

define add_impl
$(if $1$2$3,$(call add_impl2,$(call num_split_inv,$(call add1,$(firstword $1),$(firstword $2),$3)),$(wordlist 2,99,$1),$(wordlist 2,99,$2)))
endef

define add
$(call add_impl,$(call num_split_inv,$1),$(call num_split_inv,$2))
endef

define sub_impl3
$(call sub_impl2,$2,$3,$(word 2,$1))$(firstword $1)
endef

define sub_impl2
$(if $1,$(call sub_impl3,$(call sub1,$(firstword $1),$(firstword $2),$3),$(wordlist 2,99,$1),$(wordlist 2,99,$2)),$(if $2$3,f))
endef

define sub_clear_zero
$(if $(filter 0%,$1),$(call sub_clear_zero,$(1:0%=%)),$1)
endef

define sub_impl
$(call sub_clear_zero,$(call sub_impl2,$(call num_split_inv,$1),$(call num_split_inv,$2)))
endef

define sub_rev
$(if $(filter f%,$1),-$(call sub_impl,$3,$2),$1)
endef

define sub
$(call sub_rev,$(call sub_impl,$1,$2),$1,$2)
endef

define pretify
$(subst $(op)$(cp),nil,$(subst $(sp)$(cp),$(cp),$(subst $(op) ,$(op),$(subst @,$(sp),$1))))
endef

define fixup_number
$(if $1,$(if $(filter -,$1),0,$1),0)
endef

define lisp_add
$(call fixup_number,$(if $(filter -%,$1),$(if $(filter -%,$2),-$(call add,$(subst -,,$1),$(subst -,,$2)),$(call sub,$2,$(subst -,,$1))),$(if $(filter -%,$2),$(call sub,$1,$(subst -,,$2)),$(call add,$1,$2))))
endef

define lisp_sub
$(call fixup_number,$(if $(filter -%,$1),$(if $(filter -%,$2),$(call sub,$(subst -,,$2),$(subst -,,$1)),-$(call add,$2,$(subst -,,$1))),$(if $(filter -%,$2),$(call add,$1,$(subst -,,$2)),$(call sub,$1,$2))))
endef

define lisp_mul
$(if $(filter $1,0),0,$(call lisp_add,$2,$(call lisp_mul,$(call lisp_sub,$1,1),$2)))
endef

define lisp_div
$(if $(filter -%,$1),-1,$(call lisp_add,1,$(call lisp_div,$(call lisp_sub,$1,$2),$2)))
endef

define lisp_mod
$(call lisp_sub,$1,$(call lisp_mul,$(call lisp_div,$1,$2),$2))
endef

define lisp_eq
$(if $(filter $1,$2),t,nil)
endef

define lisp_neg?
$(if $(filter -%,$1),t,nil)
endef

define lisp_print
$(info PRINT: $(call pretify,$1))
endef

define isnil
$(eval t:=$(subst $(sp),@,$1))$(or $(filter $t,nil),$(filter $t,()),$(filter $t,(@)))
endef

define lisp_car
$(if $(call isnil,$1),nil,$(firstword $(call get_sexpr,$(call tail,$(subst @,$(sp),$1)))))
endef

define lisp_cdr_helper
$(if $(filter $(words $1),2),nil,(@$(subst $(sp),@,$(wordlist 2,$(call sub,$(words $1),1),$1))@))
endef

define lisp_cdr
$(if $(call isnil,$1),nil,$(call lisp_cdr_helper,$(call get_sexpr,$(call tail,$(subst @,$(sp),$1)))))
endef

define lisp_cons
$(if $(call isnil,$2),(@$1@),$(if $(filter $(op)%,$2),$(patsubst $(op)%,$(op)@$1%,$2),$(error unsupported 2nd arg for cons: $2)))
endef

define lisp_atom
$(if $(call isnil,$1),t,$(if $(filter $(op)%,$1),nil,t))
endef

define get_sexpr_impl2
$(if \
 $(filter $(op),$1),$1@$(call get_sexpr_impl,$4,$5,$3 x),$(if \
  $(filter $(cp),$1),$(if \
   $3,$(if \
    $(word 2,$3),$1@$(call get_sexpr_impl,$4,$5,$(call tail,$3)),$1 $2), \
   $(error unmatched paren (too many close))),$(if \
   $3,$1@$(call get_sexpr_impl,$4,$5,$3),$1 $2)))
endef

define get_sexpr_impl
$(if $1,$(call get_sexpr_impl2,$1,$2,$3,$(firstword $2),$(call tail,$2)),$(if $3,$(error unmatched paren (too many open))))
endef

define get_sexpr
$(call get_sexpr_impl,$(firstword $1),$(call tail,$1))
endef

define lisp_tokenize
$(subst ', ' ,$(subst $(cp), $(cp), $(subst $(op), $(op) ,$1)))
endef

define eval_args_impl
$(call eval_es,$1) $(call eval_args,$2)
endef

define eval_args
$(if $(filter $(cp),$(firstword $1)),, \
$(eval p:=$$(call get_sexpr,$$1)) \
$(call eval_args_impl,$(firstword $p),$(call tail,$p)))
endef

define check_arg1
$(if $(filter 1,$(words $2)),$(call $1,$(word 1,$2)),$(error invalid number of args ($(words $2)) for $1))
endef

define check_arg2
$(if $(filter 2,$(words $2)),$(call $1,$(word 1,$2),$(word 2,$2)),$(error invalid number of args ($(words $2)) for $1))
endef

define apply_lambda
$(eval p:=$$(call get_sexpr,$$1))
$(eval args:=$(subst @,$(sp),$(firstword $p)))
$(eval args:=$(wordlist 2,$(call sub,$(words $(args)),1),$(args)))
$(if $(filter $(words $2),$(words $(args))),,$(error invalid number of arguments for lambda (expected $(words $(args)) but given $(words $2))))
$(eval DEPTH:=$(call add,$(DEPTH),1))
$(foreach a,$(join $(foreach a,$(args),LV$$(DEPTH)_$(a):=),$2),$(eval $a))
$(eval r:=$(lastword $(call run_sexprs,$(call tail,$p))))
$(eval DEPTH:=$(call sub,$(DEPTH),1))
$(r)
endef

define eval_apply_impl
$(if $(filter +,$1),$(call check_arg2,lisp_add,$2),
$(if $(filter -,$1),$(call check_arg2,lisp_sub,$2),
$(if $(filter *,$1),$(call check_arg2,lisp_mul,$2),
$(if $(filter /,$1),$(call check_arg2,lisp_div,$2),
$(if $(filter mod,$1),$(call check_arg2,lisp_mod,$2),
$(if $(filter eq,$1),$(call check_arg2,lisp_eq,$2),
$(if $(filter neg?,$1),$(call check_arg1,lisp_neg?,$2),
$(if $(filter print,$1),$(call lisp_print,$2),
$(if $(filter car,$1),$(call check_arg1,lisp_car,$2),
$(if $(filter cdr,$1),$(call check_arg1,lisp_cdr,$2),
$(if $(filter cons,$1),$(call check_arg2,lisp_cons,$2),
$(if $(filter atom,$1),$(call check_arg1,lisp_atom,$2),
$(if $(filter lambda@%,$1),$(call apply_lambda,$(call tail,$(subst @,$(sp),$1)),$2),
$(error TODO ($1)))))))))))))))
endef

define eval_apply
$(call eval_apply_impl,$1,$(call eval_args,$2))
endef

define eval_quote
$(if $(filter quote,$1),$(subst $(sp),@,$(wordlist 1,$(call sub,$(words $2),1),$2)),$(call eval_apply,$1,$2))
endef

define run_defun
$(call eval_define,define,$1 ( lambda $2 ))
endef

define eval_defun
$(if $(filter defun,$1),$(call run_defun,$(firstword $2),$(call tail,$2)),$(call eval_quote,$1,$2))
endef

define run_lambda
$(subst $(sp),@,lambda $(wordlist 1,$(call sub,$(words $1),1),$1))
endef

define eval_lambda
$(if $(filter lambda,$1),$(call run_lambda,$2),$(call eval_defun,$1,$2))
endef

define run_define
$(if $(filter 2,$(words $2)),,invalid number of args ($(call sub,$(words $2),1)) for define)
$(eval GV_$$1:=$$(call eval_es,$$(firstword $$2)))
$1
endef

define eval_define
$(if $(filter define,$1),$(call run_define,$(firstword $2),$(call get_sexpr,$(call tail,$2))),$(call eval_lambda,$1,$2))
endef

define run_if_impl
$(eval p:=$$(call get_sexpr,$$2))
$(eval q:=$$(call get_sexpr,$$(call tail,$$p)))
$(if $(filter 2,$(words $q)),,$(error invalid number of args $(call sub,$(words $q),1) for if))
$(if $1,$(call eval_es,$(firstword $q)),$(call eval_es,$(firstword $p)))
endef

define run_if
$(call run_if_impl,$(call isnil,$(call eval_es,$1)),$2)
endef

define eval_if
$(if $(filter if,$1),$(eval p:=$$(call get_sexpr,$$2))$(call run_if,$(firstword $p),$(call tail,$p)),$(call eval_define,$1,$2))
endef

define eval_list_impl
$(call eval_if,$(call eval_es,$1),$2)
endef

define eval_list
$(eval p:=$$(call get_sexpr,$$1)) \
$(call eval_list_impl,$(firstword $p),$(call tail,$p))
endef

define eval_var
$(or $(LV$(DEPTH)_$1),$(GV_$1),$1)
endef

define eval_s
$(if $(filter $(op),$(firstword $1)),$(if $(call isnil,$1),nil,$(call eval_list,$(call tail,$1))),$(if $(filter 1,$(words $1)),$(call eval_var,$(firstword $1)),$(error invalid: $1)))
endef

define eval_es
$(strip $(call eval_s,$(subst @,$(sp),$1)))
endef

define run_sexprs_impl
$(strip $(call eval_es,$(firstword $1)))
$(call run_sexprs,$(call tail,$1))
endef

define run_sexprs
$(strip $(if $1,$(call run_sexprs_impl,$(call get_sexpr,$1))))
endef

define run_impl
$(info $(call pretify,$(strip $(call eval_es,$(firstword $1)))))
$(call run,$(call tail,$1))
endef

define run
$(strip $(if $1,$(call run_impl,$(call get_sexpr,$1))))
endef

DEPTH := 0

ifndef LISP_PROGRAM
LISP_PROGRAM := $(shell cat /dev/stdin)
endif
prog := $(LISP_PROGRAM)
prog := $(call lisp_tokenize,$(prog))

$(call run,$(prog))
