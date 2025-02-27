
WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count
    FROM aka_title mt
    LEFT JOIN cast_info cc ON mt.id = cc.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
RankedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        dk.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.cast_count DESC, dk.keyword_count ASC) AS rank
    FROM MovieCTE m
    LEFT JOIN DistinctKeywords dk ON m.movie_id = dk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name || ' (' || ct.kind || ')', ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(dk.keyword_count, 0) AS keyword_count,
    ci.companies,
    ci.company_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 in Year'
        WHEN rm.rank <= 10 THEN 'Top 10 in Year'
        ELSE 'Below Top 10'
    END AS ranking_category
FROM RankedMovies rm
LEFT JOIN CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN DistinctKeywords dk ON rm.movie_id = dk.movie_id
WHERE 
    COALESCE(rm.cast_count, 0) > 0 
    AND rm.production_year IS NOT NULL
    AND ((rm.production_year < 2000 AND COALESCE(dk.keyword_count, 0) > 5) OR 
         (rm.production_year >= 2000 AND dk.keyword_count IS NULL))
ORDER BY rm.production_year DESC, rm.cast_count DESC, COALESCE(dk.keyword_count, 0) ASC;
