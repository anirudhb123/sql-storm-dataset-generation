WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    coalesce(ac.actor_count, 0) AS total_actors,
    mk.keywords,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No actors'
        WHEN ac.actor_count > 10 THEN 'Large cast'
        ELSE 'Small cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
