WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
AggregatedCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS distinct_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieCastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT a.name) AS distinct_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ac.distinct_companies,
    ac.company_names,
    mci.distinct_actors,
    mci.actor_names,
    CASE 
        WHEN mci.distinct_actors IS NULL THEN 'No actors found'
        ELSE mci.distinct_actors::text
    END AS actor_count,
    COALESCE(mci.distinct_actors, 0) + COALESCE(ac.distinct_companies, 0) AS total_count
FROM 
    RankedMovies rm
LEFT JOIN 
    AggregatedCompanyInfo ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    MovieCastInfo mci ON rm.title_id = mci.movie_id
WHERE 
    (rm.title_rank = 1 OR rm.production_year < 2000)
    AND (mci.distinct_actors > 5 OR ac.distinct_companies IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    total_count DESC
LIMIT 25;

This SQL query contains several advanced constructs including Common Table Expressions (CTEs) to rank movies, aggregate company information, and gather cast details. It uses outer joins to combine these results, along with window functions for ranking based on production years. The query also applies a complex filtering mechanism combining COALESCE, case statements, and various predicates, which helps in handling NULL values and corner cases. The final result set includes distinct counts and concatenated strings for company and actor names, ordered as specified.
