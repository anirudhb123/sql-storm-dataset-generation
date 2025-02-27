WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title AS movie_title, 
           m.production_year, 
           1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT mm.id, 
           mm.title, 
           mm.production_year, 
           mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mm ON ml.linked_movie_id = mm.id
    WHERE mh.level < 10 -- Limit the recursion depth
)

SELECT 
    ak.name AS actor_name, 
    COALESCE(ct.kind, 'Unknown') AS cast_type,
    m.movie_title, 
    m.production_year,
    COUNT(DISTINCT c.movie_id) AS total_movies_cast,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year) AS avg_years_since_release,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM aka_name ak
LEFT JOIN cast_info c ON ak.person_id = c.person_id
LEFT JOIN movie_hierarchy m ON c.movie_id = m.movie_id
LEFT JOIN comp_cast_type ct ON c.role_id = ct.id
LEFT JOIN movie_keyword mw ON m.movie_id = mw.movie_id
LEFT JOIN keyword kw ON mw.keyword_id = kw.id
WHERE ak.name IS NOT NULL 
  AND ak.name NOT LIKE '%[!A-Za-z]%' -- Exclude any names with special characters
  AND (m.production_year < 2000 OR m.production_year IS NULL) -- Only movies before the year 2000 OR NULL
GROUP BY ak.id, ak.name, ct.kind, m.movie_title, m.production_year
HAVING COUNT(DISTINCT c.movie_id) > 5 -- Actors involved in more than 5 movies
   OR avg_years_since_release > 20 -- Movie released more than 20 years ago
ORDER BY rank, total_movies_cast DESC 
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination logic
