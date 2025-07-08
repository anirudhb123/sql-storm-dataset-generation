WITH MovieKeywordCounts AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
MovieCompanyCounts AS (
    SELECT mc.movie_id, COUNT(mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
MovieRoleCounts AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS role_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    mkc.keyword_count,
    mcc.company_count,
    mrc.role_count
FROM title t
JOIN MovieKeywordCounts mkc ON t.id = mkc.movie_id
JOIN MovieCompanyCounts mcc ON t.id = mcc.movie_id
JOIN MovieRoleCounts mrc ON t.id = mrc.movie_id
WHERE t.production_year BETWEEN 2000 AND 2023
ORDER BY t.production_year DESC, mkc.keyword_count DESC, mcc.company_count DESC;
