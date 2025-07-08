
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cs.actor_count, 0) AS total_actors,
    COALESCE(mg.genres, 'Unknown') AS genres
FROM 
    RankedMovies rm
LEFT JOIN 
    CastSummary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    rm.rn <= 5 
    AND (rm.production_year IS NOT NULL OR mg.genres IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
