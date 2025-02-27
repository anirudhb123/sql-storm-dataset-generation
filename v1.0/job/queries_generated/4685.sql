WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), MovieCast AS (
    SELECT 
        cm.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        cm.movie_id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.cast_count,
        mc.actor_names,
        CASE 
            WHEN mc.cast_count IS NULL THEN 'No Cast'
            ELSE 'Has Cast'
        END AS cast_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS total_cast,
    md.actor_names,
    md.cast_status
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.title ASC
UNION
SELECT 
    'Total Movies' AS title,
    NULL AS production_year,
    COUNT(*) AS total_cast,
    NULL AS actor_names,
    NULL AS cast_status
FROM 
    MovieDetails
WHERE 
    cast_status = 'Has Cast';
