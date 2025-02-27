WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'tv episode')
)
SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.production_year || ')', ', ') AS movies,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    movie_count DESC,
    a.name
LIMIT 10;
