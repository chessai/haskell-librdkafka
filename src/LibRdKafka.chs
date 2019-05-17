{-# language CPP #-}
{-# language DerivingStrategies #-}
{-# language ForeignFunctionInterface #-}
{-# language DuplicateRecordFields #-}
{-# language NamedFieldPuns #-}

module LibRdKafka
  ( -- * ABI compatibility
    RdKafkaT(..)
  , RdKafkaTopicT(..)
  , RdKafkaConfT(..)
  , RdKafkaTopicConfT(..)
  , RdKafkaQueueT(..)
  , RdKafkaEventT(..)
  , RdKafkaTopicResultT(..)

    -- * Types
  , RdKafkaTypeT(..)
  , RdKafkaRespErrT(..)
  , RdKafkaConfResT(..)
  , RdKafkaTimestampTypeT(..)
  , RdKafkaTopicPartitionT(..)
  , RdKafkaTopicPartitionListT(..)
  , RdKafkaMessageT(..)
  , RdKafkaMetadataBrokerT(..)
  , RdKafkaMetadataPartitionT(..)
  , RdKafkaMetadataTopicT(..)
  , RdKafkaMetadataT(..)
  , RdKafkaErrDesc(..)

    -- * Functions
  , rdKafkaVersion
  , rdKafkaVersionStr
  , rdKafkaGetDebugContexts
  , rdKafkaErr2str
  , rdKafkaErrno2err
  , rdKafkaErr2name
  ) where

import Prelude hiding (id)
import Data.Void (Void)
import Foreign.C.Types
import Foreign.Ptr (Ptr,castPtr)
import Foreign.Storable
import Foreign.C.String (CString)

#include <librdkafka/rdkafka.h>

--------------------------------------------------------------------------
-- Types (Custom)

type I64 = {#type int64_t  #}
type I32 = {#type int32_t  #}
--type I16 = {#type int16_t  #}
--type I8  = {#type int8_t   #}
-- type U64 = {#type uint64_t #}
-- type U32 = {#type uint32_t #}
-- type U16 = {#type uint16_t #}
-- type U8  = {#type uint8_t  #}

--------------------------------------------------------------------------
-- Types (Kafka)

{#enum rd_kafka_type_t as ^ {underscoreToCase} deriving (Eq,Read,Show) #}
{#enum rd_kafka_resp_err_t as ^ {underscoreToCase} deriving (Eq,Read,Show) #}
{#enum rd_kafka_conf_res_t as ^ {underscoreToCase} deriving (Eq,Read,Show) #}
{#enum rd_kafka_timestamp_type_t as ^ {underscoreToCase} deriving (Eq,Read,Show) #}

-- | rd_kafka_t
data RdKafkaT = RdKafkaT
-- {#pointer *rd_kafka_t as RdKafkaTPtr foreign -> RdKafkaT#}
{#pointer *rd_kafka_t foreign -> RdKafkaT nocode#} --as RdKafkaTPtr foreign -> RdKafkaT#}
-- | rd_kafka_topic_t
data RdKafkaTopicT = RdKafkaTopicT
{#pointer *rd_kafka_topic_t foreign -> RdKafkaTopicT nocode#}
-- | rd_kafka_conf_t
data RdKafkaConfT = RdKafkaConfT
{#pointer *rd_kafka_conf_t foreign -> RdKafkaConfT nocode#}
-- | rd_kafka_topic_conf_t
data RdKafkaTopicConfT = RdKafkaTopicConfT
{#pointer *rd_kafka_topic_conf_t foreign -> RdKafkaTopicConfT nocode#}
-- | rd_kafka_queue_t
data RdKafkaQueueT = RdKafkaQueueT
{#pointer *rd_kafka_queue_t foreign -> RdKafkaQueueT nocode#}
-- | rd_kafka_event_t
data RdKafkaEventT = RdKafkaEventT
{#pointer *rd_kafka_event_t foreign -> RdKafkaEventT nocode#}
-- | rd_kafka_topic_result_t
data RdKafkaTopicResultT = RdKafkaTopicResultT
{#pointer *rd_kafka_topic_result_t foreign -> RdKafkaTopicResultT nocode#}

-- | rd_kafka_topic_partition_t
data RdKafkaTopicPartitionT = RdKafkaTopicPartitionT
  { topic :: CString
  , partition :: I32
  , offset :: I64
  , metadata :: Ptr Void
  , metadata_size :: CULong
  , opaque :: Ptr Void
  , err :: RdKafkaRespErrT
  }
  deriving stock (Eq, Show)

instance Storable RdKafkaTopicPartitionT where
  alignment _ = {#alignof rd_kafka_topic_partition_t#}
  sizeOf _ = {#sizeof rd_kafka_topic_partition_t#}
  peek p = RdKafkaTopicPartitionT
    <$> ({#get rd_kafka_topic_partition_t->topic#} p)
    <*> ({#get rd_kafka_topic_partition_t->partition#} p)
    <*> ({#get rd_kafka_topic_partition_t->offset#} p)
    <*> fmap castPtr ({#get rd_kafka_topic_partition_t->metadata#} p)
    <*> ({#get rd_kafka_topic_partition_t->metadata_size#} p)
    <*> fmap castPtr ({#get rd_kafka_topic_partition_t->opaque#} p)
    <*> fmap cIntToEnum ({#get rd_kafka_topic_partition_t->err#} p)
  poke p RdKafkaTopicPartitionT{topic,partition,offset,metadata,metadata_size,opaque,err} = do
    {#set rd_kafka_topic_partition_t.topic#} p topic
    {#set rd_kafka_topic_partition_t.partition#} p partition
    {#set rd_kafka_topic_partition_t.offset#} p offset
    {#set rd_kafka_topic_partition_t.metadata#} p (castPtr metadata)
    {#set rd_kafka_topic_partition_t.metadata_size#} p metadata_size
    {#set rd_kafka_topic_partition_t.opaque#} p (castPtr opaque)
    {#set rd_kafka_topic_partition_t.err#} p (enumToCInt err)

-- | rd_kafka_topic_partition_list_t
data RdKafkaTopicPartitionListT = RdKafkaTopicPartitionListT
  { cnt :: CInt
  , size :: CInt
  , elems :: Ptr RdKafkaTopicPartitionT
  }
  deriving stock (Eq, Show)

instance Storable RdKafkaTopicPartitionListT where
  alignment _ = {#alignof rd_kafka_topic_partition_list_t#}
  sizeOf _ = {#sizeof rd_kafka_topic_partition_list_t#}
  peek p = RdKafkaTopicPartitionListT
    <$> ({#get rd_kafka_topic_partition_list_t->cnt #} p)
    <*> ({#get rd_kafka_topic_partition_list_t->size #} p)
    <*> fmap castPtr ({#get rd_kafka_topic_partition_list_t->elems #} p)
  poke p RdKafkaTopicPartitionListT{cnt,size,elems} = do
    {#set rd_kafka_topic_partition_list_t.cnt#} p cnt
    {#set rd_kafka_topic_partition_list_t.size#} p size
    {#set rd_kafka_topic_partition_list_t.elems#} p (castPtr elems)

-- | rd_kafka_message_t
data RdKafkaMessageT = RdKafkaMessageT
  { err :: RdKafkaRespErrT
  , rkt :: Ptr RdKafkaTopicT
  , partition :: I32
  , payload :: Ptr Void
  , len :: CULong
  , key :: Ptr Void
  , key_len :: CULong
  , offset :: I64
  }

instance Storable RdKafkaMessageT where
  alignment _ = {#alignof rd_kafka_message_t#}
  sizeOf _ = {#sizeof rd_kafka_message_t#}
  peek p = RdKafkaMessageT
    <$> fmap cIntToEnum ({#get rd_kafka_message_t->err#} p)
    <*> ({#get rd_kafka_message_t->rkt#} p)
    <*> ({#get rd_kafka_message_t->partition#} p)
    <*> fmap castPtr ({#get rd_kafka_message_t->payload#} p)
    <*> ({#get rd_kafka_message_t->len#} p)
    <*> fmap castPtr ({#get rd_kafka_message_t->key#} p)
    <*> ({#get rd_kafka_message_t->key_len#} p)
    <*> ({#get rd_kafka_message_t->offset#} p)
  poke p RdKafkaMessageT{err,rkt,partition,payload,len,key,key_len,offset} = do
    {#set rd_kafka_message_t.err#} p (enumToCInt err)
    {#set rd_kafka_message_t.rkt#} p rkt
    {#set rd_kafka_message_t.partition #} p partition
    {#set rd_kafka_message_t.payload#} p (castPtr payload)
    {#set rd_kafka_message_t.len#} p len
    {#set rd_kafka_message_t.key#} p (castPtr key)
    {#set rd_kafka_message_t.key_len#} p key_len
    {#set rd_kafka_message_t.offset#} p offset

-- | rd_kafka_metadata_broker_t
data RdKafkaMetadataBrokerT = RdKafkaMetadataBrokerT
  { id :: I32
  , host :: CString
  , port :: I32
  }

instance Storable RdKafkaMetadataBrokerT where
  alignment _ = {#alignof rd_kafka_metadata_broker_t#}
  sizeOf _ = {#sizeof rd_kafka_metadata_broker_t#}
  peek p = RdKafkaMetadataBrokerT
    <$> ({#get rd_kafka_metadata_broker_t->id#} p)
    <*> ({#get rd_kafka_metadata_broker_t->host#} p)
    <*> ({#get rd_kafka_metadata_broker_t->port#} p)
  poke p RdKafkaMetadataBrokerT{id,host,port} = do
    {#set rd_kafka_metadata_broker_t.id#} p id
    {#set rd_kafka_metadata_broker_t.host#} p host
    {#set rd_kafka_metadata_broker_t.port#} p port

-- | rd_kafka_metadata_partition_t
data RdKafkaMetadataPartitionT = RdKafkaMetadataPartitionT
  { id :: I32
  , err :: RdKafkaRespErrT
  , leader :: I32
  , replica_cnt :: CInt
  , replicas :: Ptr I32
  , isr_cnt :: CInt
  , isrs :: Ptr I32
  }

instance Storable RdKafkaMetadataPartitionT where
  alignment _ = {#alignof rd_kafka_metadata_partition_t#}
  sizeOf _ = {#sizeof rd_kafka_metadata_partition_t#}
  peek p = RdKafkaMetadataPartitionT
    <$> ({#get rd_kafka_metadata_partition_t->id#} p)
    <*> fmap cIntToEnum ({#get rd_kafka_metadata_partition_t->err#} p)
    <*> ({#get rd_kafka_metadata_partition_t->leader#} p)
    <*> ({#get rd_kafka_metadata_partition_t->replica_cnt#} p)
    <*> ({#get rd_kafka_metadata_partition_t->replicas#} p)
    <*> ({#get rd_kafka_metadata_partition_t->isr_cnt#} p)
    <*> ({#get rd_kafka_metadata_partition_t->isrs#} p)
  poke p RdKafkaMetadataPartitionT{id,err,leader,replica_cnt,replicas,isr_cnt,isrs} = do
    {#set rd_kafka_metadata_partition_t.id#} p id
    {#set rd_kafka_metadata_partition_t.err#} p (enumToCInt err)
    {#set rd_kafka_metadata_partition_t.leader#} p leader
    {#set rd_kafka_metadata_partition_t.replica_cnt#} p replica_cnt
    {#set rd_kafka_metadata_partition_t.replicas#} p replicas
    {#set rd_kafka_metadata_partition_t.isr_cnt#} p isr_cnt
    {#set rd_kafka_metadata_partition_t.isrs#} p isrs

-- | rd_kafka_metadata_topic_t
data RdKafkaMetadataTopicT = RdKafkaMetadataTopicT
  { topic :: CString
  , partition_cnt :: CInt
  , partitions :: Ptr RdKafkaMetadataPartitionT
  , err :: RdKafkaRespErrT
  }

instance Storable RdKafkaMetadataTopicT where
  alignment _ = {#alignof rd_kafka_metadata_topic_t#}
  sizeOf _ = {#sizeof rd_kafka_metadata_partition_t#}
  peek p = RdKafkaMetadataTopicT
    <$> ({#get rd_kafka_metadata_topic_t->topic#} p)
    <*> ({#get rd_kafka_metadata_topic_t->partition_cnt#} p)
    <*> fmap castPtr ({#get rd_kafka_metadata_topic_t->partitions#} p)
    <*> fmap cIntToEnum ({#get rd_kafka_metadata_topic_t->err#} p)
  poke p RdKafkaMetadataTopicT{topic,partition_cnt,partitions,err} = do
    {#set rd_kafka_metadata_topic_t.topic#} p topic
    {#set rd_kafka_metadata_topic_t.partition_cnt#} p partition_cnt
    {#set rd_kafka_metadata_topic_t.partitions#} p (castPtr partitions)
    {#set rd_kafka_metadata_topic_t.err#} p (enumToCInt err)

-- | rd_kafka_metadata_t
data RdKafkaMetadataT = RdKafkaMetadataT
  { broker_cnt :: CInt
  , brokers :: Ptr RdKafkaMetadataBrokerT
  , topic_cnt :: CInt
  , topics :: Ptr RdKafkaMetadataTopicT
  , orig_broker_id :: I32
  , orig_broker_name :: CString
  }

instance Storable RdKafkaMetadataT where
  alignment _ = {#alignof rd_kafka_metadata_t#}
  sizeOf _ = {#sizeof rd_kafka_metadata_t#}
  peek p = RdKafkaMetadataT
    <$> ({#get rd_kafka_metadata_t->broker_cnt#} p)
    <*> fmap castPtr ({#get rd_kafka_metadata_t->brokers#} p)
    <*> ({#get rd_kafka_metadata_t->topic_cnt#} p)
    <*> fmap castPtr ({#get rd_kafka_metadata_t->topics#} p)
    <*> ({#get rd_kafka_metadata_t->orig_broker_id#} p)
    <*> ({#get rd_kafka_metadata_t->orig_broker_name#} p)
  poke p RdKafkaMetadataT{broker_cnt,brokers,topic_cnt,topics,orig_broker_id,orig_broker_name} = do
    {#set rd_kafka_metadata_t.broker_cnt#} p broker_cnt
    {#set rd_kafka_metadata_t.brokers#} p (castPtr brokers)
    {#set rd_kafka_metadata_t.topic_cnt#} p topic_cnt
    {#set rd_kafka_metadata_t.topics#} p (castPtr topics)
    {#set rd_kafka_metadata_t.orig_broker_id#} p orig_broker_id
    {#set rd_kafka_metadata_t.orig_broker_name#} p orig_broker_name

data RdKafkaErrDesc = RdKafkaErrDesc
  { code :: RdKafkaRespErrT
  , name :: CString
  , desc :: CString
  }

instance Storable RdKafkaErrDesc where
  alignment _ = {#alignof rd_kafka_err_desc#}
  sizeOf _ = {#sizeof rd_kafka_err_desc#}
  peek p = RdKafkaErrDesc
    <$> fmap cIntToEnum ({#get rd_kafka_err_desc->code#} p)
    <*> ({#get rd_kafka_err_desc->name#} p)
    <*> ({#get rd_kafka_err_desc->desc#} p)
  poke p RdKafkaErrDesc{code,name,desc} = do
    {#set rd_kafka_err_desc.code#} p (enumToCInt code)
    {#set rd_kafka_err_desc.name#} p name
    {#set rd_kafka_err_desc.desc#} p desc

--------------------------------------------------------------------------
-- Functions (Kafka)

{#fun pure rd_kafka_version as
    ^ {}
    -> `Int' #}
{#fun pure rd_kafka_version_str as
    ^ {}
    -> `String' #}

{#fun pure rd_kafka_get_debug_contexts as
    ^ {}
    -> `String' #}

{#fun pure rd_kafka_err2str as
    ^ {enumToCInt `RdKafkaRespErrT'}
    -> `String' #}

{#fun pure rd_kafka_errno2err as
    ^ {`Int'}
    -> `RdKafkaRespErrT' cIntToEnum #}

{# fun pure rd_kafka_err2name as
     ^ {`RdKafkaRespErrT'}
    -> `String' #}

--{# fun rd_kafka_topic_partition_list_new as
--    ^ {`Int'}
--    -> `Ptr RdKafkaTopicPartitionListT' #}

--rd_kafka_get_err_descs


--------------------------------------------------------------------------
-- Functions (Custom)

enumToCInt :: Enum a => a -> CInt
enumToCInt = fromIntegral . fromEnum
{-# inline enumToCInt #-}

cIntToEnum :: Enum a => CInt -> a
cIntToEnum = toEnum . fromIntegral
{-# inline cIntToEnum #-}

--------------------------------------------------------------------------
