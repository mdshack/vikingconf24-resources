<?php

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Route;

Route::get('/counter', function () {
    app()->terminating(fn() => Cache::increment("counter"));

    return Cache::get("counter", 0);
});
