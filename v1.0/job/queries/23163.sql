
WITH RankedMovies AS (
  SELECT 
    at.id AS movie_id,
    at.title,
    at.production_year,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
  FROM 
    aka_title at
  WHERE 
    at.production_year IS NOT NULL
),
CastStats AS (
  SELECT 
    ci.movie_id,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS cast_with_notes
  FROM 
    cast_info ci
  GROUP BY 
    ci.movie_id
),
MovieDetails AS (
  SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_with_notes, 0) AS cast_with_notes,
    CASE 
      WHEN COALESCE(cs.total_cast, 0) = 0 THEN 'No Cast'
      ELSE CAST(COALESCE(cs.cast_with_notes, 0) * 100.0 / NULLIF(cs.total_cast, 0) AS DECIMAL(5, 2)) || '%' 
    END AS notes_percentage
  FROM 
    aka_title m
  LEFT JOIN 
    CastStats cs ON m.id = cs.movie_id
),
TopMovies AS (
  SELECT 
    rd.movie_id, 
    rd.title, 
    rd.production_year,
    rd.notes_percentage,
    RANK() OVER (ORDER BY rd.notes_percentage DESC) AS notes_rank
  FROM 
    MovieDetails rd
  WHERE 
    rd.production_year = (SELECT MAX(production_year) FROM aka_title)
)
SELECT 
  tm.title,
  tm.production_year,
  tm.notes_percentage,
  CASE 
    WHEN LENGTH(tm.notes_percentage) >= 5 THEN 'High Note Percentage'
    WHEN tm.notes_percentage = 'No Cast' THEN 'Missing Cast Information'
    ELSE 'Average Note Percentage'
  END AS note_category,
  ak.surname_pcode,
  ak.name
FROM 
  TopMovies tm
INNER JOIN 
  aka_name ak ON ak.person_id IN (
    SELECT ci.person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = tm.movie_id
  )
LEFT JOIN 
  movie_keyword mk ON mk.movie_id = tm.movie_id
WHERE 
  mk.keyword_id IN (
    SELECT k.id 
    FROM keyword k 
    WHERE k.keyword LIKE 'Action%' 
      OR k.keyword LIKE '%Adventure%'
  )
AND tm.notes_rank <= 5
ORDER BY 
  tm.notes_percentage DESC, 
  ak.name;
