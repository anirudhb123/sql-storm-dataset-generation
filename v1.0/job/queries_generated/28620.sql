WITH ranked_movies AS (
  SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    COUNT(c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
  FROM 
    title t
  JOIN 
    cast_info c ON t.id = c.movie_id
  LEFT JOIN 
    aka_title ak ON t.id = ak.movie_id
  LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
  LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
  WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
  GROUP BY 
    t.id, t.title, t.production_year
),
average_cast AS (
  SELECT 
    AVG(cast_count) AS avg_cast_count
  FROM 
    ranked_movies
),
final_benchmark AS (
  SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    rm.keywords,
    ac.avg_cast_count,
    CASE 
      WHEN rm.cast_count > ac.avg_cast_count THEN 'Above Average'
      WHEN rm.cast_count < ac.avg_cast_count THEN 'Below Average'
      ELSE 'Average'
    END AS cast_comparison
  FROM 
    ranked_movies rm
  CROSS JOIN 
    average_cast ac
)
SELECT 
  movie_id,
  title,
  production_year,
  cast_count,
  aka_names,
  keywords,
  cast_comparison
FROM 
  final_benchmark
ORDER BY 
  production_year DESC,
  cast_count DESC;
