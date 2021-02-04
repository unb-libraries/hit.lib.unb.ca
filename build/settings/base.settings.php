<?php

/**
 * @file
 * Include global settings overrides here.
 */

// Specify install profile.
$settings['install_profile'] = 'minimal';

// Redis.
$settings['cache_prefix']['default'] = 'hit_';
$conf['chq_redis_cache_enabled'] = TRUE;
require_once dirname(__FILE__) . "/settings.redis.inc";

// Newrelic.
if (extension_loaded('newrelic')) {
  require_once dirname(__FILE__) . "/settings.newrelic.inc";
}
