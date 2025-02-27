WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 as level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id, 
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    co.name AS company_name,
    COUNT(DISTINCT c.person_id) AS total_actors,
    AVG(mh.level) AS avg_depth,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    COUNT(DISTINCT km.keyword) AS total_keywords,
    ARRAY_AGG(DISTINCT CAST(m.production_year AS varchar)) FILTER (WHERE m.production_year IS NOT NULL) AS production_years
FROM 
    movie_companies mc
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    aka_title m ON mc.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    co.country_code IS NOT NULL 
    AND co.name IS NOT NULL
GROUP BY 
    co.name
ORDER BY 
    total_actors DESC
LIMIT 10;
