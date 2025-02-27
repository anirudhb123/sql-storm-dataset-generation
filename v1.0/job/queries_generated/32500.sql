WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY m.production_year DESC) AS movie_rank,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = m.id AND ci.note IS NOT NULL) AS cast_count,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = m.id AND k.keyword ILIKE '%action%') AS action_keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON cn.id = (
        SELECT mc.company_id
        FROM movie_companies mc
        WHERE mc.movie_id = m.movie_id
        LIMIT 1
    )
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND m.title IS NOT NULL
    AND (m.production_year IS NULL OR m.production_year >= 2010)
ORDER BY 
    ak.name,
    m.production_year DESC;
