WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    AVG(pi.info IS NOT NULL)::int AS has_person_info
FROM 
    cast_info a
JOIN 
    aka_name ak ON a.person_id = ak.person_id 
JOIN 
    MovieHierarchy mh ON a.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    aka_title mt ON a.movie_id = mt.id
WHERE 
    mh.depth <= 2
GROUP BY 
    a.id, ak.name, mh.movie_id, mt.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year DESC, mh.depth, actor_name
LIMIT 100;
