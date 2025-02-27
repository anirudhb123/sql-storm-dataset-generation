WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year <= 10
),
CastSummary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN r.role IS NOT NULL THEN a.person_id END) AS roles_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    DISTINCT rm.title,
    rm.production_year,
    cs.total_cast,
    cs.roles_count,
    COALESCE(mc.company_names, 'No companies') AS company_names,
    CASE 
        WHEN ds.popularity IS NULL THEN 'Not Popular'
        WHEN ds.popularity > 7 THEN 'Highly Popular'
        ELSE 'Moderately Popular'
    END AS popularity_description
FROM 
    RankedMovies rm
LEFT JOIN 
    CastSummary cs ON rm.id = cs.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.id = mc.movie_id
LEFT JOIN (
    SELECT 
        m.id AS movie_id,
        AVG(CAST(mi.info AS FLOAT)) AS popularity
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.id
) ds ON rm.id = ds.movie_id
WHERE 
    rm.rank_in_year <= 5
ORDER BY 
    rm.production_year DESC, rm.title;

This SQL query creates several Common Table Expressions (CTEs) to organize the data and allows for detailed performance benchmarking. It uses:

1. A **RankedMovies** CTE to filter and rank titles produced in the last 10 years.
2. A **CastSummary** CTE to summarize cast counts and roles.
3. A **MovieCompanies** CTE to compile company names and counts involved in each movie.
4. A final selection that consolidates the data with descriptive popularity labels based on ratings derived from the `movie_info` table, addressing NULL values for movies without ratings.

All the while, the SQL incorporates outer joins for comprehensive data retrieval, aggregate functions, window functions for ranking, and complex case expressions to handle uncommon SQL logic.
