{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Simplex.FileTransfer.Server.Stats where

import Control.Applicative ((<|>))
import qualified Data.Attoparsec.ByteString.Char8 as A
import qualified Data.ByteString.Char8 as B
import Data.Int (Int64)
import Data.Time.Clock (UTCTime)
import Simplex.Messaging.Encoding.String
import Simplex.Messaging.Protocol (SenderId)
import Simplex.Messaging.Server.Stats (PeriodStats, PeriodStatsData, getPeriodStatsData, newPeriodStats, setPeriodStats)
import UnliftIO.STM

data FileServerStats = FileServerStats
  { fromTime :: TVar UTCTime,
    filesCreated :: TVar Int,
    fileRecipients :: TVar Int,
    filesUploaded :: TVar Int,
    filesExpired :: TVar Int,
    filesDeleted :: TVar Int,
    filesDownloaded :: PeriodStats SenderId,
    fileDownloads :: TVar Int,
    fileDownloadAcks :: TVar Int,
    filesCount :: TVar Int,
    filesSize :: TVar Int64
  }

data FileServerStatsData = FileServerStatsData
  { _fromTime :: UTCTime,
    _filesCreated :: Int,
    _fileRecipients :: Int,
    _filesUploaded :: Int,
    _filesExpired :: Int,
    _filesDeleted :: Int,
    _filesDownloaded :: PeriodStatsData SenderId,
    _fileDownloads :: Int,
    _fileDownloadAcks :: Int,
    _filesCount :: Int,
    _filesSize :: Int64
  }
  deriving (Show)

newFileServerStats :: UTCTime -> IO FileServerStats
newFileServerStats ts = do
  fromTime <- newTVarIO ts
  filesCreated <- newTVarIO 0
  fileRecipients <- newTVarIO 0
  filesUploaded <- newTVarIO 0
  filesExpired <- newTVarIO 0
  filesDeleted <- newTVarIO 0
  filesDownloaded <- newPeriodStats
  fileDownloads <- newTVarIO 0
  fileDownloadAcks <- newTVarIO 0
  filesCount <- newTVarIO 0
  filesSize <- newTVarIO 0
  pure FileServerStats {fromTime, filesCreated, fileRecipients, filesUploaded, filesExpired, filesDeleted, filesDownloaded, fileDownloads, fileDownloadAcks, filesCount, filesSize}

getFileServerStatsData :: FileServerStats -> IO FileServerStatsData
getFileServerStatsData s = do
  _fromTime <- readTVarIO $ fromTime (s :: FileServerStats)
  _filesCreated <- readTVarIO $ filesCreated s
  _fileRecipients <- readTVarIO $ fileRecipients s
  _filesUploaded <- readTVarIO $ filesUploaded s
  _filesExpired <- readTVarIO $ filesExpired s
  _filesDeleted <- readTVarIO $ filesDeleted s
  _filesDownloaded <- getPeriodStatsData $ filesDownloaded s
  _fileDownloads <- readTVarIO $ fileDownloads s
  _fileDownloadAcks <- readTVarIO $ fileDownloadAcks s
  _filesCount <- readTVarIO $ filesCount s
  _filesSize <- readTVarIO $ filesSize s
  pure FileServerStatsData {_fromTime, _filesCreated, _fileRecipients, _filesUploaded, _filesExpired, _filesDeleted, _filesDownloaded, _fileDownloads, _fileDownloadAcks, _filesCount, _filesSize}

setFileServerStats :: FileServerStats -> FileServerStatsData -> STM ()
setFileServerStats s d = do
  writeTVar (fromTime (s :: FileServerStats)) $! _fromTime (d :: FileServerStatsData)
  writeTVar (filesCreated s) $! _filesCreated d
  writeTVar (fileRecipients s) $! _fileRecipients d
  writeTVar (filesUploaded s) $! _filesUploaded d
  writeTVar (filesExpired s) $! _filesExpired d
  writeTVar (filesDeleted s) $! _filesDeleted d
  setPeriodStats (filesDownloaded s) $! _filesDownloaded d
  writeTVar (fileDownloads s) $! _fileDownloads d
  writeTVar (fileDownloadAcks s) $! _fileDownloadAcks d
  writeTVar (filesCount s) $! _filesCount d
  writeTVar (filesSize s) $! _filesSize d

instance StrEncoding FileServerStatsData where
  strEncode FileServerStatsData {_fromTime, _filesCreated, _fileRecipients, _filesUploaded, _filesExpired, _filesDeleted, _filesDownloaded, _fileDownloads, _fileDownloadAcks, _filesCount, _filesSize} =
    B.unlines
      [ "fromTime=" <> strEncode _fromTime,
        "filesCreated=" <> strEncode _filesCreated,
        "fileRecipients=" <> strEncode _fileRecipients,
        "filesUploaded=" <> strEncode _filesUploaded,
        "filesExpired=" <> strEncode _filesExpired,
        "filesDeleted=" <> strEncode _filesDeleted,
        "filesCount=" <> strEncode _filesCount,
        "filesSize=" <> strEncode _filesSize,
        "filesDownloaded:",
        strEncode _filesDownloaded,
        "fileDownloads=" <> strEncode _fileDownloads,
        "fileDownloadAcks=" <> strEncode _fileDownloadAcks
      ]
  strP = do
    _fromTime <- "fromTime=" *> strP <* A.endOfLine
    _filesCreated <- "filesCreated=" *> strP <* A.endOfLine
    _fileRecipients <- "fileRecipients=" *> strP <* A.endOfLine
    _filesUploaded <- "filesUploaded=" *> strP <* A.endOfLine
    _filesExpired <- "filesExpired=" *> strP <* A.endOfLine <|> pure 0
    _filesDeleted <- "filesDeleted=" *> strP <* A.endOfLine
    _filesCount <- "filesCount=" *> strP <* A.endOfLine <|> pure 0
    _filesSize <- "filesSize=" *> strP <* A.endOfLine <|> pure 0
    _filesDownloaded <- "filesDownloaded:" *> A.endOfLine *> strP <* A.endOfLine
    _fileDownloads <- "fileDownloads=" *> strP <* A.endOfLine
    _fileDownloadAcks <- "fileDownloadAcks=" *> strP <* A.endOfLine
    pure FileServerStatsData {_fromTime, _filesCreated, _fileRecipients, _filesUploaded, _filesExpired, _filesDeleted, _filesDownloaded, _fileDownloads, _fileDownloadAcks, _filesCount, _filesSize}
