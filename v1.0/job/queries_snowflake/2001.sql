
WITH RankedMovies AS (
  SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
  FROM title t
  WHERE t.production_year IS NOT NULL
),
CastInfoCTE AS (
  SELECT 
    ci.movie_id,
    COUNT(ci.person_id) AS cast_count,
    MAX(ci.nr_order) AS max_order
  FROM cast_info ci
  JOIN aka_name a ON ci.person_id = a.person_id
  LEFT JOIN RankedMovies rm ON ci.movie_id = rm.movie_id
  GROUP BY ci.movie_id
),
MovieCompanies AS (
  SELECT 
    mc.movie_id,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
  FROM movie_companies mc
  JOIN company_name cn ON mc.company_id = cn.id
  GROUP BY mc.movie_id
),
TitleKeyword AS (
  SELECT 
    mk.movie_id,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
  FROM movie_keyword mk
  JOIN keyword k ON mk.keyword_id = k.id
  GROUP BY mk.movie_id
)
SELECT 
  rm.movie_id,
  rm.title,
  rm.production_year,
  COALESCE(ci.cast_count, 0) AS cast_count,
  COALESCE(mc.company_names, 'No companies') AS companies,
  COALESCE(tk.keywords, 'No keywords') AS keywords
FROM RankedMovies rm
LEFT JOIN CastInfoCTE ci ON rm.movie_id = ci.movie_id
LEFT JOIN MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN TitleKeyword tk ON rm.movie_id = tk.movie_id
WHERE rm.rank_within_year <= 5
ORDER BY rm.production_year DESC, rm.movie_id;
