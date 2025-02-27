WITH RECURSIVE MovieCTE AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           CASE 
               WHEN m.production_year IS NULL THEN 'Unknown Year' 
               ELSE CAST(m.production_year AS TEXT) 
           END AS year_str
    FROM aka_title m
    WHERE m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT m.id AS movie_id, m.title, m.production_year, 
           'Revisited ' || CASE 
                               WHEN m.production_year IS NULL THEN 'Unknown Year' 
                               ELSE CAST(m.production_year AS TEXT) 
                           END AS year_str
    FROM aka_title m
    JOIN MovieCTE cte ON m.id = cte.movie_id
),
CastCTE AS (
    SELECT c.movie_id, 
           COUNT(DISTINCT c.person_id) AS total_cast,
           STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
    GROUP BY c.movie_id
),
CompanyStats AS (
    SELECT mc.movie_id, 
           COUNT(cn.id) AS total_companies,
           MAX(ct.kind) AS main_company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
KeywordStats AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT m.title, m.year_str, 
       COALESCE(c.total_cast, 0) AS cast_count, 
       COALESCE(comp.total_companies, 0) AS company_count,
       COALESCE(kw.keyword_count, 0) AS keyword_count,
       CASE 
           WHEN COALESCE(c.total_cast, 0) > 0 AND 
                COALESCE(comp.total_companies, 0) > 0 
           THEN 'Movie with Cast and Companies'
           WHEN COALESCE(c.total_cast, 0) > 0 
           THEN 'Only Cast Present'
           WHEN COALESCE(comp.total_companies, 0) > 0 
           THEN 'Only Companies Present'
           ELSE 'No Cast or Companies'
       END AS movie_status
FROM MovieCTE m
LEFT JOIN CastCTE c ON m.movie_id = c.movie_id
LEFT JOIN CompanyStats comp ON m.movie_id = comp.movie_id
LEFT JOIN KeywordStats kw ON m.movie_id = kw.movie_id
WHERE m.year_str NOT LIKE '%Unknown Year%'
ORDER BY m.production_year DESC NULLS LAST, m.title
LIMIT 50;
