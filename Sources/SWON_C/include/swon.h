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

swon_result swon_parse(swon_t *dst, const char *text);
char *swon_encode(swon_t src);
void swon_free_string(char *string);
void swon_free(swon_t *dst);

swon_result swon_get_object(swon_t *dst, swon_t src, const char *field);
swon_result swon_get_number(double *dst, swon_t src);
swon_result swon_get_integer(int *dst, swon_t src);
swon_result swon_get_bool(bool *dst, swon_t src);
swon_result swon_get_string(const char **dst, swon_t src);

swon_result swon_get_array(swon_t *dst, swon_t src);
size_t swon_get_array_size(swon_t src);
swon_result swon_get_array_item(swon_t *dst, swon_t src, int index);

swon_t swon_get_map_first(swon_t src);
bool swon_get_map_exists(swon_t src);
const char *swon_get_map_key(swon_t src);
swon_t swon_get_map_next(swon_t src);

bool swon_create_array(swon_t *dst);
bool swon_array_add_item(swon_t *dst, swon_t item);

bool swon_create_object(swon_t *dst);
bool swon_object_add_item(swon_t *dst, const char *field, swon_t item);

bool swon_create_number(swon_t *dst, double value);
bool swon_create_integer(swon_t *dst, int value);
bool swon_create_bool(swon_t *dst, bool value);
bool swon_create_string(swon_t *dst, const char *value);

const char *swon_error_ptr();
