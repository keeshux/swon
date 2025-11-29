/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
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

swon_result swon_create(const char *text, swon_t *root) {
    cJSON *ret = cJSON_Parse(text);
    SWON_RETURN_IF_NULL(ret)
    root->impl = ret;
    return SWONResultValid;
}

void swon_free(swon_t root) {
    free(root.impl);
}

swon_result swon_get_object(swon_t json, const char *field, swon_t *object) {
    cJSON *item = cJSON_GetObjectItemCaseSensitive(json.impl, field);
    SWON_RETURN_IF_NULL(item)
    object->impl = item;
    return SWONResultValid;
}

swon_result swon_get_number(swon_t json, double *value) {
    SWON_RETURN_IF_NULL(json.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsNumber(json.impl))
    *value = cJSON_GetNumberValue(json.impl);
    return SWONResultValid;
}

swon_result swon_get_integer(swon_t json, int *value) {
    double double_value;
    const swon_result result = swon_get_number(json, &double_value);
    if (result != SWONResultValid) return result;
    *value = (int)double_value;
    return SWONResultValid;
}

swon_result swon_get_bool(swon_t json, bool *value) {
    SWON_RETURN_IF_NULL(json.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsBool(json.impl))
    *value = cJSON_IsTrue(json.impl);
    return SWONResultValid;
}

swon_result swon_get_string(swon_t json, const char **value) {
    SWON_RETURN_IF_NULL(json.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsString(json.impl))
    *value = cJSON_GetStringValue(json.impl);
    return SWONResultValid;
}

swon_result swon_get_array(swon_t json, swon_t *array) {
    SWON_RETURN_IF_NULL(json.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsArray(json.impl))
    array->impl = json.impl;
    return SWONResultValid;
}

size_t swon_get_array_size(swon_t json) {
    if (cJSON_IsNull(json.impl) || !cJSON_IsArray(json.impl)) return 0;
    return cJSON_GetArraySize(json.impl);
}

swon_result swon_get_array_item(swon_t json, int index, swon_t *object) {
    SWON_RETURN_IF_NULL(json.impl)
    SWON_RETURN_INVALID_IF(!cJSON_IsArray(json.impl))
    object->impl = cJSON_GetArrayItem(json.impl, index);
    return SWONResultValid;
}

swon_t swon_get_map_first(swon_t json) {
    swon_t child = { ((cJSON *)json.impl)->child };
    return child;
}

bool swon_get_map_exists(swon_t json) {
    return (cJSON *)json.impl != NULL;
}

const char *swon_get_map_key(swon_t json) {
    if (!json.impl) return NULL;
    return ((cJSON *)json.impl)->string;
}

swon_t swon_get_map_next(swon_t json) {
    swon_t next = { ((cJSON *)json.impl)->next };
    return next;
}

const char *swon_error_ptr() {
    return cJSON_GetErrorPtr();
}
