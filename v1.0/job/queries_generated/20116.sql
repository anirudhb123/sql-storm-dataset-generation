WITH RECURSIVE movie_paths AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY[m.id] AS path,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        path || ml.linked_movie_id,
        depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_paths mp ON ml.movie_id = mp.movie_id
    WHERE 
        NOT ml.linked_movie_id = ANY(path) -- Avoid cycles in paths
)

, movie_info_details AS (
    SELECT 
        mp.movie_id,
        STRING_AGG(mi.info, ' | ' ORDER BY mi.info_type_id) AS details
    FROM 
        movie_paths mp
    LEFT JOIN 
        movie_info mi ON mp.movie_id = mi.movie_id
    GROUP BY 
        mp.movie_id
)

, starred_movies AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS stars
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)

SELECT 
    at.id AS movie_id,
    at.title AS movie_title,
    COALESCE(stars, 'No stars') AS stars,
    details,
    COALESCE(cast_count, 0) AS cast_count,
    production_year
FROM 
    aka_title at
LEFT JOIN 
    movie_info_details mid ON at.id = mid.movie_id
LEFT JOIN 
    starred_movies sm ON at.id = sm.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(DISTINCT person_id) AS cast_count
     FROM 
         cast_info
     GROUP BY 
         movie_id) c ON at.id = c.movie_id
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
    AND at.production_year IS NOT NULL
    AND at.id NOT IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE phonetic_code IS NULL))
ORDER BY 
    zend_availability DESC NULLS LAST, 
    production_year DESC, 
    movie_title;

