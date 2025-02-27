WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithGenres AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count
)
SELECT 
    mwg.title,
    mwg.production_year,
    mwg.actor_count,
    mwg.keywords,
    CASE 
        WHEN mwg.actor_count > 5 THEN 'Popular'
        WHEN mwg.actor_count IS NULL THEN 'No Cast'
        ELSE 'Independent'
    END AS popularity_level
FROM 
    MoviesWithGenres mwg
WHERE 
    mwg.production_year >= 2000
    AND mwg.keywords IS NOT NULL
ORDER BY 
    mwg.actor_count DESC, 
    mwg.production_year DESC
LIMIT 
    10;
