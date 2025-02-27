WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCredits AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        mc.total_cast_count,
        mc.cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCredits mc ON rm.title_id = mc.movie_id
),
FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast_count,
        md.cast_names,
        COALESCE(md.total_cast_count, 0) AS adjusted_cast_count
    FROM 
        MovieDetails md
    WHERE 
        md.production_year > 2000 AND 
        (md.total_cast_count IS NULL OR md.total_cast_count > 5)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.adjusted_cast_count,
    CASE 
        WHEN fm.adjusted_cast_count < 10 THEN 'Small Cast'
        WHEN fm.adjusted_cast_count BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Large Cast'
    END AS cast_size
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.adjusted_cast_count DESC
LIMIT 50;
