WITH RECURSIVE MovieHierarchy AS (
  SELECT
    mt.id AS movie_id,
    mt.title,
    mt.production_year,
    1 AS level
  FROM 
    aka_title mt
  WHERE 
    mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
  
  UNION ALL
  
  SELECT
    ml.linked_movie_id AS movie_id,
    at.title,
    at.production_year,
    mh.level + 1 AS level
  FROM 
    MovieHierarchy mh
  JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
  JOIN 
    aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
  ak.name AS actor_name,
  mt.title AS movie_title,
  YEAR(CURRENT_DATE) - mt.production_year AS years_since_release,
  STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
  COUNT(DISTINCT cc.person_id) AS co_actors_count,
  MAX(pi.info) AS highest_rating_info,
  CASE
    WHEN COUNT(DISTINCT cc.person_id) > 10 THEN 'Ensemble Cast'
    ELSE 'Small Cast'
  END AS cast_size
FROM 
  aka_name ak
JOIN 
  cast_info cc ON ak.person_id = cc.person_id
JOIN 
  movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
  MovieHierarchy m ON mc.movie_id = m.movie_id
LEFT JOIN 
  movie_keyword mw ON m.movie_id = mw.movie_id
LEFT JOIN 
  keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
  movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
  info_type it ON mi.info_type_id = it.id
LEFT JOIN 
  person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
  ak.name IS NOT NULL
  AND m.production_year >= 2000
  AND (it.info IS NULL OR it.info != 'N/A')
GROUP BY 
  ak.name, m.title, m.production_year
ORDER BY 
  years_since_release DESC, co_actors_count DESC
LIMIT 50;
