WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'fe%')
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        count(c.id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(am.actor_count, 0) AS actor_count,
        mwk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.actor_count,
    dmi.keywords,
    CASE 
        WHEN dmi.actor_count >= 5 THEN 'Ensemble Cast'
        WHEN dmi.actor_count = 0 THEN 'No Actors Listed'
        ELSE 'Small Cast'
    END AS cast_size,
    EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = dmi.movie_id 
        AND cc.status_id = (SELECT id FROM info_type WHERE info LIKE 'released%')
    ) AS is_released
FROM 
    DetailedMovieInfo dmi
WHERE 
    (dmi.production_year BETWEEN 2000 AND 2020 OR dmi.production_year IS NULL)
    AND (dmi.keywords ILIKE '%action%' OR dmi.keywords IS NULL)
ORDER BY 
    dmi.production_year DESC,
    dmi.actor_count DESC
LIMIT 100;
