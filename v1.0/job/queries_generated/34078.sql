WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
SELECT 
    a.name AS Actor_Name,
    COUNT(DISTINCT mc.movie_id) AS Movies_Acted,
    (SELECT COUNT(*) 
     FROM play_role pr
     WHERE pr.person_id = c.person_id) AS Total_Roles,
    SUM(CASE 
            WHEN mc.company_id IS NULL THEN 0 
            ELSE 1 
         END) AS Movies_With_Companies,
    STRING_AGG(DISTINCT ct.kind, ', ') AS Company_Types,
    MAX(mh.production_year) AS Latest_Movies_Year,
    AVG(mh.production_year) AS Avg_Movies_Year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    mh.production_year BETWEEN 1990 AND 2023  -- Filtering the production years
    AND a.name IS NOT NULL 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5 -- Only including actors who have acted in more than 5 movies
ORDER BY 
    Movies_Acted DESC, Actor_Name ASC;

