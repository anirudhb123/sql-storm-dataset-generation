WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name, 
    at.title AS movie_title,
    mh.production_year,
    COUNT(*) OVER (PARTITION BY a.id) AS movie_count,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - pi.info::timestamp))) AS avg_years_since_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'release date')
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    a.name IS NOT NULL
    AND mh.depth = 1
    AND (mi.info IS NULL OR mi.info::timestamp < (CURRENT_TIMESTAMP - INTERVAL '5 years'))
ORDER BY 
    movie_count DESC,
    actor_name;

-- Additional components for benchmarking
EXPLAIN (ANALYZE, BUFFERS)
WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
), role_summary AS (
    SELECT 
        r.role AS role_type,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        role_type r
    JOIN 
        cast_info ci ON r.id = ci.role_id
    GROUP BY 
        r.role
)
SELECT 
    ma.actor_name,
    ma.movie_count,
    COALESCE(rs.actor_count, 0) AS unique_actors_per_role
FROM 
    movie_actors ma
LEFT JOIN 
    role_summary rs ON rs.role_type = (
        SELECT rn.role
        FROM role_type rn
        JOIN cast_info ci ON rn.id = ci.role_id
        WHERE ci.person_id = ma.actor_id
        LIMIT 1)  -- Assumes one role per actor for simplicity
ORDER BY 
    ma.movie_count DESC,
    ma.actor_name;
