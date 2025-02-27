WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT mt.title, '; ') AS movie_titles,
    COUNT(DISTINCT mt.id) AS total_movies,
    MAX(mt.production_year) AS last_movie_year,
    SUM(CASE 
        WHEN mt.production_year IS NOT NULL THEN 1 ELSE 0 
    END) AS rated_movies,
    COALESCE(MIN(mt.production_year) FILTER (WHERE mt.production_year >= 2000), 'No movies since 2000') AS first_recent_movie_year,
    AVG(COALESCE(DATE_PART('year', now()) - mt.production_year, 0)) AS avg_years_since_release,
    COUNT(DISTINCT mh.parent_id) AS num_related_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND (mt.production_year BETWEEN 1980 AND 2023 OR mt.title ILIKE '%Adventure%')
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mt.id) > 5 
ORDER BY 
    total_movies DESC, last_movie_year DESC
LIMIT 50;
