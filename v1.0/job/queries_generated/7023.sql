WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_title
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        tm.total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopRatedMovies tm ON rm.movie_id = tm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast
FROM 
    MovieDetails md
WHERE 
    md.total_cast IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 10;
