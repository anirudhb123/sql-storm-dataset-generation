WITH RankedMovies AS (
  SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(c.id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_members,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords_array
  FROM 
    aka_title m
  LEFT JOIN 
    cast_info c ON m.id = c.movie_id
  LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
  LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
  LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
  WHERE 
    m.production_year >= 2000  
  GROUP BY 
    m.id, m.title, m.production_year
),
TopMovies AS (
  SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    cast_members,
    keywords_array,
    RANK() OVER (ORDER BY cast_count DESC) AS rank
  FROM 
    RankedMovies
)

SELECT 
  tm.title,
  tm.production_year,
  tm.cast_count,
  tm.cast_members,
  ARRAY_LENGTH(tm.keywords_array, 1) AS keyword_count
FROM 
  TopMovies tm
WHERE 
  tm.rank <= 10  
ORDER BY 
  tm.rank;