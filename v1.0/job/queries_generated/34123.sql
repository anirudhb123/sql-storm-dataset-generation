WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
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
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    a.name AS actor_name,
    CASE 
        WHEN c.kind IS NOT NULL THEN c.kind 
        ELSE 'Unknown Role' 
    END AS company_type,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
FROM 
    MovieHierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    mh.level <= 3 
    AND (m.production_year BETWEEN 2000 AND 2023)
    AND (k.keyword IS NULL OR k.keyword NOT LIKE '%action%')
ORDER BY 
    m.production_year DESC, 
    movie_id, 
    actor_rank;
