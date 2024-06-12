<?php

ignore_user_abort(true);

require __DIR__ . '/vendor/autoload.php';

// Init Prometheus
$prom = \Prometheus\CollectorRegistry::getDefault();

// Init router
$router = new \Bramus\Router\Router();

// Init Redis
$redis = new Predis\Client();

$handler = static function () use ($prom, $router, $redis) {
    $prom
        ->getOrRegisterCounter('', 'active_connections', 'number of active connections')
        ->inc();

    $router->get("counter", function() use ($redis) {
        $count = ((int) $redis->get("counter")) ?? 0;
        $count++;
        
        $redis->set("counter", $count);

        echo $count;
    });

    $router->get("metrics", function() use ($prom) {
        $renderer = new \Prometheus\RenderTextFormat();
        $result = $renderer->render($prom->getMetricFamilySamples());

        echo $result;
    });

    $router->run();

    $prom
        ->getOrRegisterCounter('', 'active_connections', 'number of active connections')
        ->incBy(-1);
};

$maxRequests = (int)($_SERVER['MAX_REQUESTS'] ?? 50);
for ($nbRequests = 0; !$maxRequests || $nbRequests < $maxRequests; ++$nbRequests) {
    $keepRunning = \frankenphp_handle_request($handler);

    // Do something after sending the HTTP response

    // Call the garbage collector to reduce the chances of it being triggered in the middle of a page generation
    gc_collect_cycles();

    if (!$keepRunning) break;
}

// Cleanup
