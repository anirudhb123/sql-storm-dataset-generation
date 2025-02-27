WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL  -- Base case: Select all movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mv.movie_id) AS total_movies,
    AVG(mv.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mv.movie_title, ', ') AS movie_titles,
    CASE 
        WHEN COUNT(DISTINCT mv.movie_id) > 10 THEN 'Frequent Actor'
        WHEN COUNT(DISTINCT mv.movie_id) BETWEEN 5 AND 10 THEN 'Occasional Actor'
        ELSE 'Rare Actor'
    END AS actor_frequency
FROM 
    cast_info cv
JOIN 
    aka_name ak ON cv.person_id = ak.person_id
JOIN 
    (SELECT 
         mv.id AS movie_id,
         mv.title AS movie_title,
         mv.production_year
     FROM 
         aka_title mv
     INNER JOIN 
         movie_info mi ON mv.id = mi.movie_id
     WHERE 
         mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
         AND mi.info IS NOT NULL) AS mv ON cv.movie_id = mv.movie_id
LEFT JOIN 
    complete_cast cc ON cv.movie_id = cc.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(*) AS cast_count
     FROM 
         cast_info
     GROUP BY 
         movie_id
     HAVING 
         COUNT(*) > 1) AS mc ON mv.movie_id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    mv.person_id, ak.name
ORDER BY 
    total_movies DESC,
    avg_production_year DESC
LIMIT 100;

-- Additional query to benchmark with optional NULL logic
SELECT 
    ct.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_notes,
    AVG(EXTRACT(YEAR FROM NOW()) - mv.production_year) AS avg_years_since_release
FROM 
    movie_companies mc
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    aka_title mv ON mc.movie_id = mv.id
WHERE 
    mv.production_year IS NOT NULL
GROUP BY 
    ct.kind
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC;
