WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        m.episode_of_id
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'episode')
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ct.id) AS cast_count,
    COALESCE(SUM(mi.info::text), 'No info') AS movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ct.nr_order) AS actor_order,
    mh.level AS movie_level
FROM 
    cast_info ct
INNER JOIN 
    aka_name a ON ct.person_id = a.person_id
INNER JOIN 
    MovieHierarchy mh ON ct.movie_id = mh.movie_id
INNER JOIN 
    aka_title t ON ct.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year IS NOT NULL
    AND t.title IS NOT NULL
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, t.production_year, mh.level
ORDER BY 
    movie_level, actor_name;
