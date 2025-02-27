WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        row_number() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT kind.id FROM kind_type kind WHERE kind.kind = 'movie')
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        ak.name,
        amc.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts amc ON ak.person_id = amc.person_id
    WHERE 
        amc.movie_count >= (
            SELECT 
                AVG(movie_count) FROM ActorMovieCounts
        )
)
SELECT 
    rm.title,
    rm.production_year,
    ta.name AS top_actor,
    COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    TopActors ta ON ci.person_id = ta.person_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
