
WITH MovieDetails AS (
  SELECT 
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ci.id) AS total_cast,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
  FROM aka_title at
  LEFT JOIN cast_info ci ON at.id = ci.movie_id
  LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
  WHERE at.production_year >= 2000
  GROUP BY at.id, at.title, at.production_year
),
CompanyDetails AS (
  SELECT 
    mc.movie_id,
    COUNT(DISTINCT cn.name) AS num_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
  FROM movie_companies mc
  JOIN company_name cn ON mc.company_id = cn.id
  WHERE cn.country_code IS NOT NULL
  GROUP BY mc.movie_id
),
CompleteDetails AS (
  SELECT 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.cast_with_notes,
    COALESCE(cd.num_companies, 0) AS num_companies,
    md.cast_names
  FROM MovieDetails md
  LEFT JOIN CompanyDetails cd ON md.movie_title = (
    SELECT title FROM aka_title WHERE id = cd.movie_id
  )
)
SELECT 
  movie_title AS title,
  production_year,
  total_cast,
  cast_with_notes,
  num_companies,
  cast_names
FROM CompleteDetails
ORDER BY production_year DESC, total_cast DESC
LIMIT 10;
