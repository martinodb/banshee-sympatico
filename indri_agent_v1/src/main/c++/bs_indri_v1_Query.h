/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class bs_indri_v1_Query */

#ifndef _Included_bs_indri_v1_Query
#define _Included_bs_indri_v1_Query
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     bs_indri_v1_Query
 * Method:    query_begin
 * Signature: ([Ljava/lang/String;Ljava/lang/String;)I
 */
JNIEXPORT jint JNICALL Java_bs_indri_v1_Query_query_1begin
  (JNIEnv *, jobject, jobjectArray, jstring);

/*
 * Class:     bs_indri_v1_Query
 * Method:    query_next_results
 * Signature: (II[Ljava/lang/String;)Ljava/util/Map;
 */
JNIEXPORT jobject JNICALL Java_bs_indri_v1_Query_query_1next_1results
  (JNIEnv *, jobject, jint, jint, jobjectArray);

/*
 * Class:     bs_indri_v1_Query
 * Method:    query_close
 * Signature: (I)V
 */
JNIEXPORT void JNICALL Java_bs_indri_v1_Query_query_1close
  (JNIEnv *, jobject, jint);

#ifdef __cplusplus
}
#endif
#endif
