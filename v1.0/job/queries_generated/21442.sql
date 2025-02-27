WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(NULL AS text) AS parent_title,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        r.movie_id AS parent_title,
        r.hierarchy_level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        RecursiveMovieCTE r ON r.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name, 
    COUNT(DISTINCT cm.movie_id) AS total_movies,
    MIN(r.production_year) AS earliest_movie_year,
    MAX(r.production_year) AS latest_movie_year,
    ARRAY_AGG(DISTINCT r.title || ' (' || r.production_year || ')') AS movies_list,
    STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    RecursiveMovieCTE r ON r.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = r.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
WHERE 
    a.name IS NOT NULL 
    AND a.name <> ''
    AND ci.nr_order < 5
    AND EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = r.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    )
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT r.movie_id) > 3
ORDER BY 
    total_movies DESC
LIMIT 10;
