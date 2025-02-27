WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT ch.name) AS character_count,
    COUNT(DISTINCT a.id) AS actor_count,
    AVG(CASE WHEN mot.note IS NOT NULL THEN 1 ELSE 0 END) AS has_multiple_keywords_flag,
    mt.production_year,
    STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name) AS actor_names,
    COUNT(DISTINCT m.id) AS unique_movie_count,
    SUM(COALESCE(mi.info LIKE '%Oscar%', 0)::int) AS oscar_count
FROM
    movie_keyword mk
JOIN 
    aka_title at ON mk.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = at.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = at.id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    mov_info mi ON mi.movie_id = at.id AND mi.note IS NULL
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    (SELECT 
         movie_id,
         STRING_AGG(DISTINCT keyword, ', ') AS note
     FROM 
         movie_keyword
     GROUP BY 
         movie_id
     HAVING 
         COUNT(DISTINCT keyword) > 1) mot ON mot.movie_id = at.id
WHERE 
    at.production_year > 2000
    AND (mk.keyword IS NOT NULL OR mk.keyword NOT LIKE '%trailer%')
GROUP BY 
    mk.keyword,
    mt.production_year
ORDER BY 
    COUNT(DISTINCT ch.name) DESC,
    mt.production_year DESC
LIMIT 100;
