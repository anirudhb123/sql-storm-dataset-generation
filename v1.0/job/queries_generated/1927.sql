WITH movie_years AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count
    FROM aka_title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
), ranked_movies AS (
    SELECT 
        mt.production_year,
        mt.title,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank
    FROM aka_title mt
    JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT c.id) OVER (PARTITION BY ak.person_id) AS total_movies,
    mv.movie_count,
    (SELECT COUNT(*) 
     FROM movie_keyword mk
     WHERE mk.movie_id = at.id
     AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('comedy', 'drama'))) AS keyword_count,
    CASE WHEN ak.id IS NULL THEN 'Unknown Actor' ELSE ak.name END AS actor_name_safe
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    aka_title at ON c.movie_id = at.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_years mv ON at.production_year = mv.production_year
WHERE 
    ak.name IS NOT NULL
AND 
    at.production_year > 2000
AND 
    EXISTS (SELECT 1 FROM role_type rt WHERE rt.id = c.role_id AND rt.role = 'actor')
ORDER BY 
    total_movies DESC, 
    movie_title
LIMIT 50;
