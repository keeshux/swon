/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <stdbool.h>
#include <stddef.h>

typedef struct {
    void *impl;
} swon_t;

typedef enum {
    SWONResultValid,
    SWONResultInvalid,
    SWONResultNull
} swon_result;

swon_result swon_create(const char *text, swon_t *root);
void swon_free(swon_t root);

swon_result swon_get_object(swon_t json, const char *field, swon_t *object);
swon_result swon_get_number(swon_t json, double *value);
swon_result swon_get_integer(swon_t json, int *value);
swon_result swon_get_bool(swon_t json, bool *value);
swon_result swon_get_string(swon_t json, const char **value);

swon_result swon_get_array(swon_t json, swon_t *array);
size_t swon_get_array_size(swon_t json);
swon_result swon_get_array_item(swon_t json, int index, swon_t *object);

swon_t swon_get_map_first(swon_t json);
bool swon_get_map_exists(swon_t json);
const char *swon_get_map_key(swon_t json);
swon_t swon_get_map_next(swon_t json);

const char *swon_error_ptr();
