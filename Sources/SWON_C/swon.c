/*
 * SPDX-FileCopyrightText: 2026 Davide De Rosa
 *
 * SPDX-License-Identifier: MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"

#include "swon.h"

#define SWON_RETURN_IF_NULL(o) \
    if (!o || cJSON_IsNull(o)) return SWONResultNull;

#define SWON_RETURN_RESULT_IF_INVALID(r) if (r != SWONResultValid) return r;
#define SWON_RETURN_INVALID_IF(expr) if (expr) return SWONResultInvalid;

swon_result swon_parse(swon_t *dst, const char *text) {
    cJSON *ret = cJSON_Parse(text);
    SWON_RETURN_IF_NULL(ret)
    dst->impl = ret;
    return SWONResultValid;
}

const char *swon_parse_error_ptr() {
    return cJSON_GetErrorPtr();
}

char *swon_encode(swon_t src) {
    return cJSON_PrintUnformatted(src.impl);
}

void swon_free_string(char *string) {
    if (!string) return;
    cJSON_free(string);
}

void swon_free(swon_t *dst) {
    if (!dst->impl) return;
    cJSON_Delete(dst->impl);
}

swon_result swon_get_object(swon_t *dst, swon_t src, const char *field) {
    cJSON *item = cJSON_GetObjectItemCaseSensitive(src.impl, field);
    SWON_RETURN_IF_NULL(item)
    SWON_RETURN_INVALID_IF(!cJSON_IsObject(src.impl))
    dst->impl = item;
    return SWONResultValid;
}

swon_result swon_get_number(double *dst, swon_t src) {
    SWON_RETURN_IF_NULL(src.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsNumber(src.impl))
    *dst = cJSON_GetNumberValue(src.impl);
    return SWONResultValid;
}

swon_result swon_get_integer(int *dst, swon_t src) {
    double double_value;
    const swon_result result = swon_get_number(&double_value, src);
    if (result != SWONResultValid) return result;
    *dst = (int)double_value;
    return SWONResultValid;
}

swon_result swon_get_bool(bool *dst, swon_t src) {
    SWON_RETURN_IF_NULL(src.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsBool(src.impl))
    *dst = cJSON_IsTrue(src.impl);
    return SWONResultValid;
}

swon_result swon_get_string(const char **dst, swon_t src) {
    SWON_RETURN_IF_NULL(src.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsString(src.impl))
    *dst = cJSON_GetStringValue(src.impl);
    return SWONResultValid;
}

swon_result swon_get_array(swon_t *dst, swon_t src) {
    SWON_RETURN_IF_NULL(src.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsArray(src.impl))
    dst->impl = src.impl;
    return SWONResultValid;
}

size_t swon_get_array_size(swon_t src) {
    if (cJSON_IsNull(src.impl) || !cJSON_IsArray(src.impl)) return 0;
    return cJSON_GetArraySize(src.impl);
}

swon_result swon_get_array_item(swon_t *object, swon_t src, int index) {
    SWON_RETURN_IF_NULL(src.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsArray(src.impl))
    object->impl = cJSON_GetArrayItem(src.impl, index);
    return SWONResultValid;
}

swon_t swon_get_map_first(swon_t src) {
    swon_t child = { ((cJSON *)src.impl)->child };
    return child;
}

bool swon_get_map_exists(swon_t src) {
    return (cJSON *)src.impl != NULL;
}

const char *swon_get_map_key(swon_t src) {
    if (!src.impl) return NULL;
    return ((cJSON *)src.impl)->string;
}

swon_t swon_get_map_next(swon_t src) {
    swon_t next = { ((cJSON *)src.impl)->next };
    return next;
}

bool swon_create_array(swon_t *dst) {
    dst->impl = cJSON_CreateArray();
    return dst->impl;
}

bool swon_array_add_item(swon_t *dst, swon_t item) {
    return cJSON_AddItemToArray(dst->impl, item.impl);
}

bool swon_create_object(swon_t *dst) {
    dst->impl = cJSON_CreateObject();
    return dst->impl;
}

bool swon_object_add_item(swon_t *dst, const char *field, swon_t item) {
    return cJSON_AddItemToObject(dst->impl, field, item.impl);
}

bool swon_create_number(swon_t *dst, double value) {
    dst->impl = cJSON_CreateNumber(value);
    return dst;
}

bool swon_create_integer(swon_t *dst, int value) {
    dst->impl = cJSON_CreateNumber(value);
    return dst;
}

bool swon_create_bool(swon_t *dst, bool value) {
    dst->impl = cJSON_CreateBool(value);
    return dst;
}

bool swon_create_string(swon_t *dst, const char *value) {
    dst->impl = cJSON_CreateString(value);
    return dst;
}
