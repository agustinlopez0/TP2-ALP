{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
module Paths_TP2 (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/bin"
libdir     = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/lib/x86_64-linux-ghc-8.8.3/TP2-0.1.0.0-HulsqrtklG321LN7cs02Q6"
dynlibdir  = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/lib/x86_64-linux-ghc-8.8.3"
datadir    = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/share/x86_64-linux-ghc-8.8.3/TP2-0.1.0.0"
libexecdir = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/libexec/x86_64-linux-ghc-8.8.3/TP2-0.1.0.0"
sysconfdir = "/home/agustin/TP2-ALP/.stack-work/install/x86_64-linux/deb1244e473f29b4ab1c0708da0552ed4648eab8a6ca8bea965142fff5e1e924/8.8.3/etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "TP2_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "TP2_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "TP2_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "TP2_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "TP2_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "TP2_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
