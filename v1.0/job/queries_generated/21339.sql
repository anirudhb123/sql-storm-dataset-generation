WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT m.id) OVER (PARTITION BY a.production_year) AS movie_count
    FROM aka_title a
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
      AND a.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        p.id AS person_id,
        p.gender,
        ARRAY_AGG(DISTINCT c.note) AS notes,
        COUNT(DISTINCT ci.movie_id) AS movie_appearances,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    GROUP BY p.id, p.gender
),
NullCheckMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(SUM(mi.info_type_id IS NULL::int), 0) AS null_info_count
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    GROUP BY t.id
)
SELECT 
    rm.title,
    rm.production_year,
    a.gender,
    a.movie_appearances,
    NULLIF(NULLIF(rm.movie_count, 0), 1) AS adjusted_movie_count,
    ncm.null_info_count AS movies_with_null_info
FROM RankedMovies rm
JOIN ActorInfo a ON a.movie_appearances > 5
LEFT JOIN NullCheckMovies ncm ON ncm.title = rm.title
WHERE rm.year_rank = 1
  AND a.notes IS NOT NULL
ORDER BY rm.production_year DESC, a.movie_appearances DESC
LIMIT 100 OFFSET 20;

WITH TotalCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        array_agg(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    t.title,
    t.production_year,
    c.company_count,
    c.companies,
    CASE 
        WHEN c.company_count > 5 THEN 'Many Companies'
        WHEN c.company_count IS NULL OR c.company_count = 0 THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_description
FROM title t
LEFT JOIN TotalCompanyCounts c ON t.id = c.movie_id
WHERE t.production_year >= 2000
  AND (c.company_count IS NOT NULL OR c.companies IS NULL)
ORDER BY t.production_year, c.company_count DESC;
