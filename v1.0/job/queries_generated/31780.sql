WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1,
        path || mt.title
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
)

SELECT 
    m.movie_title,
    STRING_AGG(DISTINCT ka.name, ', ') AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT mi.info) AS info_entries,
    COALESCE(ct.kind, 'No Company') AS company_type,
    m.depth,
    m.path
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
WHERE 
    m.depth = 1 -- Limit to top-level movies
GROUP BY 
    m.movie_title, ct.kind, m.depth, m.path
ORDER BY 
    m.movie_title
LIMIT 50;
