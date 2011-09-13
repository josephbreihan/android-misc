#!/usr/bin/perl -w
use strict;

#############################################################################
# agcc.pl android toolchain wrapper
# Copyright 2008, Andrew Ross andy@plausible.org

# Modified by Joseph Breihan <android@josephbreihan.com>
# to work with version r6b of the Android NDK.

# This version was modified from a previously modified copy obtained from:
# http://android-cruft.googlecode.com/svn-history/r2/trunk/ndk/agcc.pl

# - changes in paths
# - removed hardcoding of toolchain binary names and version
# - updated cpu-specific optimizations for ARM Cortex-a9
#   (since I have a Motorola Xoom)
# - I have not tested everything but have built some packages successfully
#   with this script.  Please also see a related script here:
#   https://github.com/tmurakam/droid-wrapper
#   His looks better but I don't have it working yet.

# When cross-compiling a project using autotools for android you may
# need to update config.guess and config.sub in each project directory
# to recent versions.

# Run configure with LD=agcc.pl CC=agcc.pl ./configure

# The toolchain is called $TOOLCHAINID-*

# Android NDK root directory and gcc details
my $ANDROIDNDK="/opt/android-ndk";
my $GCCVERSION="4.4.3";
my $TOOLCHAINID="arm-linux-androideabi";

# Contrary to original notes, I've updated the CPU flags for Tegra2:
my $MCPU='cortex-a9';
my $MTUNE='cortex-a9';
#my $MARCH='armv7-a'; #I think this needs a newer gcc
my $MFPU='vfpv3-d16';

#############################################################################
# Notes from the original author follow below. 
#############################################################################

# Copyright 2008, Andrew Ross andy@plausible.org
# Distributable under the terms of the GNU GPL, see COPYING for details

# The Android toolchain is ... rough.  Rather than try to manage the
# complexity directly, this script wraps the tools into an "agcc" that
# works a lot like a gcc command line does for a native platform or a
# properly integrated cross-compiler.  It accepts arbitrary arguments,
# but interprets the following specially:
#
# -E/-S/-c/-shared - Enable needed arguments (linker flags, include
#                    directories, runtime startup objects...) for the
#                    specified compilation mode when building under
#                    android.
#
# -O<any> - Turn on the optimizer flags used by the Dalvik build.  No
#           control is provided over low-level optimizer flags.
#
# -W<any> - Turn on the warning flags used by the Dalvik build.  No
#           control is provided over specific gcc warning flags.
#
# Notes:
# + The prebuilt arm-eabi-gcc from a built (!) android source
#   directory must be on your PATH.
# + All files are compiled with -fPIC to an ARMv5TE target.  No
#   support is provided for thumb.
# + No need to pass a "-Wl,-soname" argument when linking with
#   -shared, it uses the file name always (so don't pass a directory in
#   the output path for a shared library!)

# Dance around to find the actual android toolchain path (it's very
# deep, so links on $PATH are going to be common.
my $GCC = `which $TOOLCHAINID-gcc`;
$GCC = qx(cd `dirname $GCC`; /bin/pwd);
chomp $GCC;
die "bad $TOOLCHAINID-gcc path" if $GCC !~ /(.*)\/prebuilt\//;



my $ALIB = "$ANDROIDNDK/platforms/android-9/arch-arm/usr/lib";
my $PREBUILT="$ANDROIDNDK/toolchains/$TOOLCHAINID-$GCCVERSION/prebuilt/linux-x86";
my $TOOLCHAIN = "$PREBUILT/$TOOLCHAINID-$GCCVERSION";
my $INTERWORK = "$PREBUILT/lib/gcc/$TOOLCHAINID/$GCCVERSION";
my $LDSCRIPTS = "$PREBUILT/$TOOLCHAINID/lib/ldscripts";

#leaving this on broke some builds
#print "GCC at $GCC \n";
#print "ANDROIDNDK at $ANDROIDNDK \n";
#print "TOOLCHAIN at $TOOLCHAIN \n";
#print "\n\n\n";

my @include_paths = (
"-I$ANDROIDNDK/system/core/include",
"-I$ANDROIDNDK/hardware/libhardware/include",
"-I$ANDROIDNDK/hardware/ril/include",
"-I$ANDROIDNDK/dalvik/libnativehelper/include",
"-I$ANDROIDNDK/frameworks/base/include",
"-I$ANDROIDNDK/external/skia/include",
"-I$ANDROIDNDK/platforms/android-9/arch-arm/usr/include",
"-I$ANDROIDNDK/bionic/libc/arch-arm/include",
"-I$ANDROIDNDK/bionic/libc/include",
"-I$ANDROIDNDK/bionic/libstdc++/include",
"-I$ANDROIDNDK/bionic/libc/kernel/common",
"-I$ANDROIDNDK/bionic/libc/kernel/arch-arm",
"-I$ANDROIDNDK/bionic/libm/include",
"-I$ANDROIDNDK/bionic/libm/include/arch/arm",
"-I$ANDROIDNDK/bionic/libthread_db/include",
"-I$ANDROIDNDK/bionic/libm/arm",
"-I$ANDROIDNDK/bionic/libm",
#"-I/home/josephb/projects/xoom/system/include",
"-I$ANDROIDNDK/out/target/product/generic/obj/SHARED_LIBRARIES/libm_intermediates");

my @preprocess_args = (
"-DANDROID",
"-DSK_RELEASE",
"-DNDEBUG",
# "-include", "$DROID/system/core/include/arch/linux-arm/AndroidConfig.h",
"-UDEBUG");
#"-D__ARM_ARCH_5__",
#"-D__ARM_ARCH_5T__",
#"-D__ARM_ARCH_5E__",
#"-D__ARM_ARCH_5TE__", # Already defined by toolchain

my @warn_args = (
"-Wall",
"-Wno-unused", # why?
"-Wno-multichar", # why?
"-Wstrict-aliasing=2"); # Implicit in -Wall per texinfo

my @compile_args = (
"-mcpu=$MCPU",
"-mtune=$MTUNE",
#"-march=$MARCH", #I think this needs a newer gcc
"-mfpu=$MFPU",
"-msoft-float",
"-mthumb-interwork",
"-fpic",
"-fno-exceptions",
"-ffunction-sections",
"-funwind-tables", # static exception-like tables
"-fstack-protector", # check guard variable before return
"-fmessage-length=0"); # No line length limit to error messages

my @optimize_args = (
"-O2",
"-finline-functions",
"-finline-limit=300",
"-fno-inline-functions-called-once",
"-fgcse-after-reload",
"-frerun-cse-after-loop", # Implicit in -O2 per texinfo
"-frename-registers",
"-fomit-frame-pointer",
"-fstrict-aliasing", # Implicit in -O2 per texinfo
"-funswitch-loops");

my @link_args = (
"-Bdynamic",
"-Wl,-T,$LDSCRIPTS/armelf_linux_eabi.x",
"-Wl,-dynamic-linker,/system/bin/linker",
"-Wl,--gc-sections",
"-Wl,-z,nocopyreloc",
"-Wl,--no-undefined",
"-Wl,-rpath-link=$ALIB",
"-L$ALIB",
#"-L/home/josephb/projects/xoom/system/lib",
"-nostdlib",
"$ALIB/crtend_android.o",
"$ALIB/crtbegin_dynamic.o",
"-lc",
"$INTERWORK/libgcc.a",
"$ALIB/libc.a",
"-lm");

# Also need: -Wl,-soname,libXXXX.so
my @shared_args = (
"-nostdlib",
"-Wl,-T,$LDSCRIPTS/armelf_linux_eabi.xsc",
"-Wl,--gc-sections",
"-Wl,-shared,-Bsymbolic",
"-L$ALIB",
"-Wl,--no-whole-archive",
"-lc",
"-lm",
"-Wl,--no-undefined",
"$INTERWORK/libgcc.a",
"-Wl,--whole-archive"); # .a, .o input files go *after* here

# Now implement a quick parser for a gcc-like command line

my %MODES = ("-E"=>1, "-c"=>1, "-S"=>1, "-shared"=>1);

my $mode = "DEFAULT";
my $out;
my $warn = 0;
my $opt = 0;
my @args = ();
my $have_src = 0;
while(@ARGV) {
   my $a = shift;
   if(defined $MODES{$a}) {
#die "Can't specify $a and $mode" if $mode ne "DEFAULT";
      $mode = $a;
   } elsif($a eq "-o") {
      die "Missing -o argument" if !@ARGV;
      die "Duplicate -o argument" if defined $out;
      $out = shift;
   } elsif($a =~ /^-W.*/) {
      $warn = 1;
   } elsif($a =~ /^-O.*/) {
      $opt = 1;
   } else {
      if($a =~ /\.(c|cpp|cxx)$/i) { $have_src = 1; }
      push @args, $a;
   }
}

my $need_cpp = 0;
my $need_compile = 0;
my $need_link = 0;
my $need_shlink = 0;
if($mode eq "DEFAULT") { $need_cpp = $need_compile = $need_link = 1; }
if($mode eq "-E") { $need_cpp = 1; }
if($mode eq "-c") { $need_cpp = $need_compile = 1; }
if($mode eq "-S") { $need_cpp = $need_compile = 1; }
if($mode eq "-shared") { $need_shlink = 1; }

if($have_src and $mode ne "-E") { $need_cpp = $need_compile = 1; }

# Assemble the command:
my @cmd = ("$TOOLCHAINID-gcc");
if($mode ne "DEFAULT") { @cmd = (@cmd, $mode); }
if(defined $out) { @cmd = (@cmd, "-o", $out); }
if($need_cpp) { @cmd = (@cmd, @include_paths, @preprocess_args); }
if($need_compile){
   @cmd = (@cmd, @compile_args);
   if($warn) { @cmd = (@cmd, @warn_args); }
   if($opt) { @cmd = (@cmd, @optimize_args); }
}
if($need_shlink) { @cmd = (@cmd, @shared_args); }
@cmd = (@cmd, @args);
if($need_link) { @cmd = (@cmd, @link_args); }

print join(" ", @cmd), "\n"; # Spit it out if you're curious
exec(@cmd);

