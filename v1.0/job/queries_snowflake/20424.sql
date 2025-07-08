
WITH RECURSIVE RecursiveMovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS link_level,
        ARRAY_AGG(ml.linked_movie_id) OVER (PARTITION BY ml.movie_id) AS path
    FROM
        movie_link ml
    WHERE ml.link_type_id IN (SELECT id FROM link_type WHERE link ILIKE 'sequel%')
        
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rml.link_level + 1,
        rml.path || ml.linked_movie_id
    FROM 
        movie_link ml
    INNER JOIN 
        RecursiveMovieLinks rml ON ml.movie_id = rml.linked_movie_id
    WHERE 
        ml.linked_movie_id NOT IN (SELECT value FROM TABLE(FLATTEN(input => rml.path)))  
),
FilteredMovieInfo AS (
    SELECT 
        mt.movie_id,
        mt.production_year,
        mt.title,
        COALESCE(MAX(CONCAT(mi.info, ' ', mi.note)), 'No Info') AS movie_info
    FROM
        aka_title mt
    LEFT JOIN 
        movie_info_idx mi ON mt.movie_id = mi.movie_id
    GROUP BY 
        mt.movie_id, mt.production_year, mt.title
)
SELECT 
    a.name AS actor_name,
    f.movie_id,
    f.title,
    f.production_year,
    f.movie_info,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    COUNT(DISTINCT ml.linked_movie_id) AS sequel_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    FilteredMovieInfo f ON c.movie_id = f.movie_id
LEFT JOIN 
    RecursiveMovieLinks ml ON f.movie_id = ml.movie_id
WHERE 
    f.movie_info IS NOT NULL
    AND (a.name ILIKE 'J%' OR a.name ILIKE 'A%')
    AND EXISTS (
        SELECT 1
        FROM movie_keyword mk
        WHERE mk.movie_id = f.movie_id
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword ILIKE '%action%')
    )
GROUP BY 
    a.name, f.movie_id, f.title, f.production_year, f.movie_info
HAVING
    COUNT(DISTINCT ml.linked_movie_id) >= 1
ORDER BY 
    f.production_year DESC NULLS LAST, 
    a.name;
