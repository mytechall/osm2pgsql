/**
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This file is part of osm2pgsql (https://osm2pgsql.org/).
 *
 * Copyright (C) 2006-2023 by the osm2pgsql developer community.
 * For a full list of authors see the git log.
 */

#include "format.hpp"
#include "pgsql.hpp"
#include "pgsql-helper.hpp"

#include <cassert>

idlist_t get_ids_from_result(pg_result_t const &result) {
    idlist_t ids;
    assert(result.num_tuples() >= 0);
    ids.reserve(static_cast<std::size_t>(result.num_tuples()));

    for (int i = 0; i < result.num_tuples(); ++i) {
        ids.push_back(osmium::string_to_object_id(result.get_value(i, 0)));
    }

    return ids;
}

idlist_t get_ids_from_db(pg_conn_t const *db_connection, char const *stmt,
                         osmid_t id)
{
    auto const res = db_connection->exec_prepared(stmt, id);
    return get_ids_from_result(res);
}

void create_geom_check_trigger(pg_conn_t *db_connection,
                               std::string const &schema,
                               std::string const &table,
                               std::string const &condition)
{
    std::string const func_name =
        qualified_name(schema, table + "_osm2pgsql_valid");

    db_connection->exec("CREATE OR REPLACE FUNCTION {}()\n"
                        "RETURNS TRIGGER AS $$\n"
                        "BEGIN\n"
                        "  IF {} THEN \n"
                        "    RETURN NEW;\n"
                        "  END IF;\n"
                        "  RETURN NULL;\n"
                        "END;"
                        "$$ LANGUAGE plpgsql",
                        func_name, condition);

    db_connection->exec("CREATE TRIGGER \"{}\""
                        " BEFORE INSERT OR UPDATE"
                        " ON {}"
                        " FOR EACH ROW EXECUTE PROCEDURE"
                        " {}()",
                        table + "_osm2pgsql_valid",
                        qualified_name(schema, table), func_name);
}

void drop_geom_check_trigger(pg_conn_t *db_connection,
                             std::string const &schema,
                             std::string const &table)
{
    std::string const func_name =
        qualified_name(schema, table + "_osm2pgsql_valid");

    db_connection->exec(R"(DROP TRIGGER "{}" ON {})",
                        table + "_osm2pgsql_valid",
                        qualified_name(schema, table));

    db_connection->exec("DROP FUNCTION IF EXISTS {} ()", func_name);
}

void analyze_table(pg_conn_t const &db_connection, std::string const &schema,
                   std::string const &name)
{
    auto const qual_name = qualified_name(schema, name);
    db_connection.exec("ANALYZE {}", qual_name);
}

bool has_table(pg_conn_t const &db_connection, std::string const &schema,
               std::string const &table)
{
    auto const sql = fmt::format("SELECT count(*) FROM pg_tables"
                                 " WHERE schemaname='{}' AND tablename='{}'",
                                 schema.empty() ? "public" : schema, table);
    auto const res = db_connection.exec(sql);
    char const *const num = res.get_value(0, 0);

    return num[0] == '1' && num[1] == '\0';
}
