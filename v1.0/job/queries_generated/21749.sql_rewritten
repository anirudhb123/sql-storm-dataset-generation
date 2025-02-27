WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        AVG(ci.nr_order) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.id AS movie_id,
        t.production_year,
        COALESCE(cc.total_cast, 0) AS total_cast,
        COALESCE(cc.distinct_roles, 0) AS distinct_roles,
        COALESCE(cc.avg_order, 0) AS avg_order,
        CASE 
            WHEN t.production_year IS NOT NULL THEN EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year 
            ELSE NULL 
        END AS age_of_movie
    FROM 
        title t
    LEFT JOIN 
        CastCounts cc ON t.id = cc.movie_id
),
HighRankedMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.rank_per_year > 5 THEN 'Top Performers'
            ELSE 'Average'
        END AS performance_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year IS NOT NULL
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.distinct_roles,
    ROUND(md.avg_order, 2) AS avg_cast_order,
    md.age_of_movie,
    hr.performance_category
FROM 
    MovieDetails md
JOIN 
    HighRankedMovies hr ON md.movie_id = hr.title_id
WHERE 
    md.age_of_movie IS NOT NULL
    AND (md.total_cast > 10 OR md.distinct_roles > 5)
ORDER BY 
    md.production_year DESC, md.total_cast DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;