WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- top-level movies

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(p.gender, 'Unknown') AS gender,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT ca.person_id) AS num_actors,
    AVG(CASE WHEN CAST(ci.note AS BOOLEAN) IS TRUE THEN 1 ELSE 0 END) AS has_special_note,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_within_year
FROM 
    aka_title m
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    cast_info ca ON ca.movie_id = m.id
LEFT JOIN 
    name p ON p.id = ca.person_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = m.id
WHERE 
    m.production_year >= 2000
    AND (m.title ILIKE '%action%' OR m.title ILIKE '%drama%')
GROUP BY 
    m.id, p.gender
HAVING 
    COUNT(DISTINCT ca.person_id) > 5  -- Only movies with more than 5 actors
ORDER BY 
    m.production_year DESC, rank_within_year;
