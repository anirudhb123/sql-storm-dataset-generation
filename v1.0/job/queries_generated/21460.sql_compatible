
WITH RecursiveCast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),

MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ka.name, 'Unknown') AS main_actor,
        rc.distinct_cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_name ka ON mt.id = ka.id
    LEFT JOIN 
        RecursiveCast rc ON mt.id = rc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),

FilteredMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.main_actor,
        md.distinct_cast_count,
        md.movie_rank,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era_category
    FROM
        MovieDetails md
    WHERE 
        md.distinct_cast_count IS NOT NULL
        AND md.production_year >= 1980
),

TopMovies AS (
    SELECT 
        era_category,
        AVG(distinct_cast_count) AS avg_cast_count,
        COUNT(*) AS movie_count
    FROM 
        FilteredMovies
    GROUP BY 
        era_category
)

SELECT 
    t.era_category,
    t.avg_cast_count,
    t.movie_count,
    STRING_AGG(md.title, ', ') AS movie_titles
FROM 
    TopMovies t
LEFT JOIN 
    FilteredMovies md ON t.era_category = md.era_category
GROUP BY 
    t.era_category, t.avg_cast_count, t.movie_count
ORDER BY 
    t.avg_cast_count DESC;
