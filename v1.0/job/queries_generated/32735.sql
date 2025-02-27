WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    k.keyword AS keyword,
    COUNT(DISTINCT a.id) AS actor_count,
    AVG(COALESCE(m.production_year, 0)) AS avg_production_year,
    STRING_AGG(DISTINCT m.title, ', ') AS released_movies,
    RANK() OVER (PARTITION BY k.keyword ORDER BY COUNT(DISTINCT a.id) DESC) AS actor_rank

FROM 
    keyword k
LEFT JOIN 
    movie_keyword mk ON k.id = mk.keyword_id
LEFT JOIN 
    aka_title m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = m.id

WHERE 
    k.keyword IS NOT NULL 
    AND (m.production_year IS NOT NULL OR a.name IS NOT NULL)

GROUP BY 
    k.keyword

HAVING 
    COUNT(DISTINCT a.id) > 5

ORDER BY 
    actor_rank ASC, avg_production_year DESC;
