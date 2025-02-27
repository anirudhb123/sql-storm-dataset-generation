WITH RECURSIVE MoviesCTE AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           1 AS level
    FROM aka_title mt
    WHERE mt.production_year = 2020
    
    UNION ALL
    
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           level + 1
    FROM aka_title m
    INNER JOIN MoviesCTE mc ON m.episode_of_id = mc.movie_id
)
SELECT person_name.name AS actor_name,
       movie.title AS movie_title,
       movie.production_year,
       COUNT(DISTINCT comp.id) AS company_count,
       AVG(rating.rating) AS avg_rating,
       STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM MoviesCTE movie
JOIN cast_info c ON movie.movie_id = c.movie_id
LEFT JOIN aka_name person_name ON c.person_id = person_name.person_id
LEFT JOIN movie_companies mc ON movie.movie_id = mc.movie_id
LEFT JOIN company_name comp ON mc.company_id = comp.id
LEFT JOIN movie_keyword mk ON movie.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN (
    SELECT movie_id, 
           AVG(rating) AS rating
    FROM movie_info 
    WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY movie_id
) rating ON movie.movie_id = rating.movie_id
WHERE COALESCE(comp.country_code, 'Unknown') = 'USA'
  AND movie.production_year > 1990
  AND person_name.name IS NOT NULL
GROUP BY person_name.name, movie.title, movie.production_year
ORDER BY avg_rating DESC, movie.production_year DESC;
