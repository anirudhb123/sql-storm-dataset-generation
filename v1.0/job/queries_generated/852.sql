WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM title AS m
    WHERE m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ca.movie_id,
        COUNT(ca.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info AS ca
    JOIN aka_name AS ak ON ca.person_id = ak.person_id
    GROUP BY ca.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COALESCE(COUNT(mc.company_id), 0) AS total_companies
    FROM movie_companies AS mc
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    cd.total_cast,
    cd.cast_names,
    COALESCE(mc.total_companies, 0) AS total_companies,
    CASE 
        WHEN mc.total_companies IS NOT NULL THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status
FROM RankedMovies AS rm
LEFT JOIN CastDetails AS cd ON rm.movie_id = cd.movie_id
LEFT JOIN MovieCompanies AS mc ON rm.movie_id = mc.movie_id
WHERE rm.production_year BETWEEN 2000 AND 2020
  AND EXISTS (
      SELECT 1
      FROM movie_keyword AS mk
      WHERE mk.movie_id = rm.movie_id
        AND mk.keyword_id IN (SELECT k.id FROM keyword AS k WHERE k.keyword LIKE '%Action%')
  )
ORDER BY rm.production_year DESC, rm.movie_title
LIMIT 10;
