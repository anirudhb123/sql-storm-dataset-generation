WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        MAX(k.keyword) OVER (PARTITION BY t.id) AS top_keyword
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    GROUP BY ca.movie_id
),
CompanySummary AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MovieInfoWithNulls AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END) AS budget,
        MAX(CASE WHEN it.info = 'Revenue' THEN mi.info ELSE NULL END) AS revenue,
        COALESCE(MAX(CASE WHEN it.info = 'Budget' THEN mi.info END), 'Not Specified') AS budget_status
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.cast_count,
    cd.actors,
    cs.companies,
    cs.company_count,
    mi.budget,
    mi.revenue,
    CASE 
        WHEN mi.budget IS NULL AND mi.revenue IS NULL THEN 'No Financial Info'
        WHEN mi.budget IS NOT NULL AND mi.budget::numeric < mi.revenue::numeric THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS financial_status,
    COALESCE(rm.top_keyword, 'No Keywords') AS top_keyword,
    CASE WHEN rm.year_rank = 1 THEN 'Latest Movie of the Year' ELSE '' END AS year_status
FROM RankedMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN CompanySummary cs ON rm.movie_id = cs.movie_id
LEFT JOIN MovieInfoWithNulls mi ON rm.movie_id = mi.movie_id
WHERE rm.production_year BETWEEN 2000 AND 2023
  AND (cd.cast_count IS NOT NULL OR cs.company_count IS NOT NULL)
ORDER BY rm.production_year DESC, cd.cast_count DESC;
