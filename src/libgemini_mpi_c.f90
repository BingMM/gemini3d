!> This module contains C/CXX wrappers for functions in libgemini_mpi.  These routines match those in libgemini_mpi.f90 and are
!!   principally meant to convert the C pointers to various data objects into fortran pointers (including in the case of the
!!   grid a class pointer (pointer to polymorphic object).  Other polymorhpic objects (neutraldata, etc.) are kept in a static
!!   derived type (intvars::gemini_work) and don't need to be passes as class pointers.
module gemini3d_mpi_C

use, intrinsic :: iso_c_binding, only : c_f_pointer, C_PTR, C_INT, wp => C_DOUBLE

use phys_consts, only : lsp
use meshobj, only: curvmesh
use config, only: gemini_cfg
use io, only: output_plasma,output_aur,find_milestone,input_plasma,create_outdir
use potential_comm, only: get_BGEfields,velocities
use grid, only: lx1,lx2,lx3
use grid_mpi, only: grid_drift, read_grid
use collisions, only: conductivities
use potentialBCs_mumps, only: init_Efieldinput
use potential_comm,only : pot2perpfield, electrodynamics
use neutral_perturbations, only: init_neutralperturb,neutral_denstemp_update,neutral_wind_update,neutral_perturb
use temporal, only : dt_comm
use sanity_check, only : check_finite_pertub, check_finite_output
use advec_mpi, only: set_global_boundaries_allspec, halo_interface_vels_allspec
use multifluid_mpi, only: halo_allparams
use sources_mpi, only: RK2_prep_mpi_allspec
use ionization_mpi, only: get_gavg_Tinf
use neutral_perturbations, only: clear_dneu

use gemini3d, only: fluidvar_pointers,fluidauxvar_pointers, electrovar_pointers, gemini_work
use gemini3d_mpi, only: outdir_fullgridvaralloc, get_initial_state, check_fileoutput
use gemini3d_C, only : set_gridpointer_dyntype

implicit none (type, external)

contains

!> create output directory and allocate full grid potential storage
subroutine outdir_fullgridvaralloc_C(cfgC,intvarsC,lx1,lx2all,lx3all) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: lx1,lx2all,lx3all

  type(gemini_cfg), pointer :: cfg
  type(gemini_work), pointer :: intvars

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)

  call outdir_fullgridvaralloc(cfg, intvars, lx1, lx2all, lx3all)
end subroutine outdir_fullgridvaralloc_C

!! TODO: allocatable X, how to handle?
! subroutine read_grid_in_C(cfgC, xtype, xC) bind(C)
!   type(C_PTR), intent(in) :: cfgC
!   integer(C_INT), intent(in) :: xtype
!   type(C_PTR), intent(inout) :: xC

!   type(gemini_cfg), pointer :: cfg
!   class(curvmesh), pointer :: x

!   call c_f_pointer(cfgC, cfg)
!   x=>set_gridpointer_dyntype(xtype, xC)

!   call read_grid(cfg%indatsize,cfg%indatgrid,cfg%flagperiodic, x)
!   !! read in a previously generated grid from filenames listed in input file
! end subroutine read_grid_in_C

subroutine get_initial_state_C(cfgC,fluidvarsC,electrovarsC,intvarsC,xtype, xC,UTsec,ymd,tdur) bind(C)
  type(C_PTR), intent(inout) :: cfgC
  type(c_ptr), intent(inout) :: fluidvarsC
  type(c_ptr), intent(inout) :: electrovarsC
  type(C_PTR), intent(inout) :: intvarsC
  integer(C_INT), intent(in) :: xtype
  type(C_PTR), intent(inout) :: xC
  real(wp), intent(inout) :: UTsec
  integer(C_INT), dimension(3), intent(inout) :: ymd
  real(wp), intent(inout) :: tdur

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars
  real(wp), dimension(:,:,:,:), pointer :: electrovars
  type(gemini_work), pointer :: intvars
  class(curvmesh), pointer :: x

  call c_f_pointer(cfgC, cfg)
  call c_f_pointer(intvarsC,intvars)
  x=>set_gridpointer_dyntype(xtype, xC)

  call c_f_pointer(fluidvarsC,fluidvars,[(lx1+4),(lx2+4),(lx3+4),(5*lsp)])
  call c_f_pointer(electrovarsC,electrovars,[(lx1+4),(lx2+4),(lx3+4),(2*lsp+9)])

  call get_initial_state(cfg, fluidvars,electrovars,intvars, x, UTsec, ymd, tdur)
end subroutine get_initial_state_C

subroutine check_fileoutput_C(cfgC,fluidvarsC,electrovarsC,intvarsC,t,tout,tglowout,tmilestone,flagoutput,ymd,UTsec) bind(C)
  type(C_PTR), intent(in) :: cfgC
  type(c_ptr), intent(inout) :: fluidvarsC
  type(c_ptr), intent(inout) :: electrovarsC
  type(C_PTR), intent(inout) :: intvarsC
  real(wp), intent(in) :: t
  real(wp), intent(inout) :: tout,tglowout,tmilestone
  integer(C_INT), intent(inout) :: flagoutput
  integer(C_INT), dimension(3), intent(in) :: ymd
  real(wp), intent(in) :: UTsec

  type(gemini_cfg), pointer :: cfg
  real(wp), dimension(:,:,:,:), pointer :: fluidvars
  real(wp), dimension(:,:,:,:), pointer :: electrovars
  type(gemini_work), pointer :: intvars

  call check_fileoutput(cfg, fluidvars, electrovars, intvars, t, tout,tglowout,tmilestone,flagoutput,ymd,UTsec)
end subroutine check_fileoutput_C

end module gemini3d_mpi_C
