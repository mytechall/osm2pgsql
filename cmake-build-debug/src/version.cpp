/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This file is part of osm2pgsql (https://osm2pgsql.org/).
 *
 * Copyright (C) 2006-2023 by the osm2pgsql developer community.
 * For a full list of authors see the git log.
 */

char const *get_build_type() noexcept
{
    return "Debug";
}

char const *get_osm2pgsql_version() noexcept
{
    return "1.8.1 (1.8.1-18-gcf96d478)";
}

char const *get_osm2pgsql_short_version() noexcept
{
    return "1.8.1";
}

char const *get_minimum_postgresql_server_version() noexcept
{
    return "9.6";
}

unsigned long get_minimum_postgresql_server_version_num() noexcept
{
    return 90600;
}

