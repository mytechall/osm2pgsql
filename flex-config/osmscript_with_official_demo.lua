---
--- Generated by Luanalysis
--- Created by mymac.
--- DateTime: 2023/3/29 10:03
---

print('osm2pgsql version: ' .. osm2pgsql.version)

local srid = 4326

local tables = {}

tables.nodes = osm2pgsql.define_node_table('nodes', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'point', projection = srid },
    { column = 'version', type = 'int' },
    { column = 'changeset', type = 'int' },
    -- There is no built-in type for timestamps in osm2pgsql. So we use the
    -- PostgreSQL type "timestamp" and then have to convert our timestamps
    -- to a valid text representation for that type.
    --
    -- Timestamps in OSM are always in UTC, depending on your use case you
    -- might want to store them using "timestamptz" instead.
    -- See https://github.com/openstreetmap/osm2pgsql/issues/1785
    { column = 'created', sql_type = 'timestamp' },
    { column = 'uid', type = 'int' },
    { column = 'user', type = 'text' },
}, {schema = 'first_schema'})

tables.ways = osm2pgsql.define_way_table('ways', {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'linestring', projection = srid },
    { column = 'version', type = 'int' },
    { column = 'changeset', type = 'int' },
    { column = 'created', sql_type = 'timestamp' },
    { column = 'uid', type = 'int' },
    { column = 'user', type = 'text' },
    { column = 'nodes', type = 'text', sql_type = 'bigint[]' },
} , {schema = 'first_schema'})

tables.relations = osm2pgsql.define_relation_table('relations', {
    { column = 'tags', type = 'jsonb' },
    { column = 'version', type = 'int' },
    { column = 'changeset', type = 'int' },
    { column = 'created', sql_type = 'timestamp' },
    { column = 'uid', type = 'int' },
    { column = 'user', type = 'text' },
    { column = 'members', type = 'jsonb' },
}, {schema = 'first_schema'})

function format_date(ts)
    return os.date('!%Y-%m-%dT%H:%M:%SZ', ts)
end

function object_to_string(object)
    local tags = {}

    -- 将 tags 属性转换为一个字符串
    for k, v in pairs(object.tags) do
        table.insert(tags, string.format('%s=%s', k, v))
    end

    -- 将其他属性组合成一个字符串
    local props = {
        string.format('id=%d', object.id),
        string.format('type=%s', object.type),
        --string.format('version=%d', object.version),
        string.format('timestamp=%s', object.timestamp),
        --string.format('changeset=%d', object.changeset),
        --string.format('uid=%d', object.uid),
        string.format('user=%s', object.user),
    }

    -- 将所有属性组合成一个字符串
    local str = table.concat(props, ',')
    if #tags > 0 then
        str = str .. ',' .. table.concat(tags, ',')
    end

    return str
end

function osm2pgsql.process_node(object)
    if next(object.tags) == nil then
        return
    end

    local object_str = object_to_string(object)
    print(object_str)  -- 输出到控制台

    tables.nodes:insert({
        tags = object.tags,
        geom = object:as_point(),
        version = object.version,
        changeset = object.changeset,
        created = format_date(object.timestamp),
        uid = object.uid,
        user = object.user
    })
end

function osm2pgsql.process_way(object)
    if not osm2pgsql then
        print("Error: osm2pgsql not loaded")
        return
    end
    local object_str = object_to_string(object)
    print(object_str)  -- 输出到控制台
    tables.ways:insert({
        tags = object.tags,
        geom = object:as_linestring(),
        version = object.version,
        changeset = object.changeset,
        created = format_date(object.timestamp),
        uid = object.uid,
        user = object.user,
        nodes = '{' .. table.concat(object.nodes, ',') .. '}'
    })
end

function osm2pgsql.process_relation(object)
    if not osm2pgsql then
        print("Error: osm2pgsql not loaded")
        return
    end
    local object_str = object_to_string(object)
    print(object_str)  -- 输出到控制台
    tables.relations:insert({
        tags = object.tags,
        version = object.version,
        changeset = object.changeset,
        created = format_date(object.timestamp),
        uid = object.uid,
        user = object.user,
        members = object.members
    })
end