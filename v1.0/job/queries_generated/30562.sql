WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.imdb_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        ml2.title,
        ml2.production_year,
        ml2.imdb_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ml2 ON ml.linked_movie_id = ml2.id
)
SELECT 
    p.id AS person_id,
    coalesce(a.name, 'Unknown') AS actor_name,
    count(DISTINCT mc.movie_id) AS movies_count,
    array_agg(DISTINCT mk.keyword) AS keywords,
    nm.kind AS company_type
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_type nm ON mc.company_type_id = nm.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    nm.kind IS NOT NULL
GROUP BY 
    p.id, a.name, nm.kind
HAVING 
    count(DISTINCT mc.movie_id) > 5
ORDER BY 
    movies_count DESC NULLS LAST;
