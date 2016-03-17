#!/bin/sh


SRC_DIR=.
DST_DIR=.
PROTO_DIR=.

../protobuf-ios/bin/protoc -I=$SRC_DIR --cpp_out=$DST_DIR $PROTO_DIR/message.proto
