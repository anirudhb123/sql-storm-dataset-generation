WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select all root movies (those without a parent episode)
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        ARRAY[mt.id] AS path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL

    -- Recursive case: join with episodes to find all sub-episodes
    SELECT
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level,
        mh.path || et.id
    FROM
        aka_title et
    JOIN
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)

-- Main query
SELECT
    m.id AS movie_id,
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    MAX(p.info) AS notes,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE 
        WHEN COUNT(DISTINCT mk.keyword) > 5 THEN 'Popular' 
        ELSE 'Less Popular' 
    END AS popularity_category
FROM
    movie_hierarchy m
LEFT JOIN
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN
    person_info p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
GROUP BY
    m.id, m.title, m.production_year
HAVING
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY
    m.production_year DESC, popularity_category DESC;

-- Performance Benchmarking: Evaluated aggregate functions, CTEs, joins, and sorting complexity
