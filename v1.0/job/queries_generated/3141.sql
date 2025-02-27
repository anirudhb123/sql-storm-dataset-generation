WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%comedy%'
),
ActorCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    CASE 
        WHEN rm.rn = 1 THEN 'First in Year'
        WHEN rm.rn = rm.total_movies THEN 'Last in Year'
        ELSE 'Middle Film'
    END AS film_position,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No Cast Info'
        WHEN ac.actor_count > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.id = ac.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.title;
