WITH RankedMovies AS (
  SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    COUNT(c.id) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
  FROM 
    title t
  LEFT JOIN 
    cast_info c ON t.id = c.movie_id
  WHERE 
    t.production_year IS NOT NULL
  GROUP BY 
    t.id, t.title, t.production_year
),
TopMovies AS (
  SELECT 
    movie_id, title, production_year
  FROM 
    RankedMovies
  WHERE 
    rank <= 5
),
CharacterNames AS (
  SELECT 
    DISTINCT cn.name AS character_name,
    mk.movie_id
  FROM 
    movie_keyword mk
  JOIN 
    keyword k ON mk.keyword_id = k.id
  WHERE 
    k.keyword LIKE '%action%'
),
Companies AS (
  SELECT 
    mc.movie_id,
    cn.name AS company_name,
    ct.kind AS company_type
  FROM 
    movie_companies mc
  JOIN 
    company_name cn ON mc.company_id = cn.id
  JOIN 
    company_type ct ON mc.company_type_id = ct.id
)
SELECT 
  tm.title,
  tm.production_year,
  COALESCE(MAX(cn.character_name), 'No Character') AS character_name,
  COALESCE(MAX(comp.company_name), 'No Companies') AS companies,
  ct.kind AS company_type,
  tm.cast_count
FROM 
  TopMovies tm
LEFT JOIN 
  CharacterNames cn ON tm.movie_id = cn.movie_id
LEFT JOIN 
  Companies comp ON tm.movie_id = comp.movie_id
LEFT JOIN 
  comp_cast_type ct ON ct.id = (
    SELECT 
      c.person_role_id
    FROM 
      cast_info c
    WHERE 
      c.movie_id = tm.movie_id
    LIMIT 1
  )
GROUP BY 
  tm.movie_id, tm.title, tm.production_year, ct.kind
ORDER BY 
  tm.production_year DESC, tm.cast_count DESC;
