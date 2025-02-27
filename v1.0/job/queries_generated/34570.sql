WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit the recursion depth to 3
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(CAST(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id), INTEGER), 0) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN mt.production_year < 2000 THEN 'Classic'
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category,
    COUNT(DISTINCT c.id) AS total_cast
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
GROUP BY 
    ak.name, mt.id, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.id) > 2 -- Filtering for movies with more than 2 cast members
ORDER BY 
    mt.production_year DESC, role_count DESC;

This query performs a performance benchmark across multiple tables with a recursive CTE to explore movie relationships. It counts roles, aggregates keywords, applies filtering predicates, and categorizes movies by era—all while incorporating NULL logic and grouping to enhance complexity.
