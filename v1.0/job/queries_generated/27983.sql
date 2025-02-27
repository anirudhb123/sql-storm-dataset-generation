WITH ranked_movies AS (
  SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT ak.name) AS aliases,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
  FROM 
    title m
  JOIN 
    cast_info c ON m.id = c.movie_id
  LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
  LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
  LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
  GROUP BY 
    m.id, m.title, m.production_year
),
top_movies AS (
  SELECT 
    movie_id, 
    title, 
    production_year, 
    actor_count, 
    aliases, 
    keywords,
    RANK() OVER (ORDER BY actor_count DESC) AS rank
  FROM 
    ranked_movies
)
SELECT 
  tm.rank,
  tm.title,
  tm.production_year,
  tm.actor_count,
  ARRAY_TO_STRING(tm.aliases, ', ') AS actor_aliases,
  ARRAY_TO_STRING(tm.keywords, ', ') AS movie_keywords
FROM 
  top_movies tm
WHERE 
  tm.production_year >= 2000
ORDER BY 
  tm.rank
LIMIT 10;
