WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword ILIKE '%action%'
), 
ActorMovies AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_actors
    FROM 
        cast_info ca
    JOIN 
        RankedMovies rm ON ca.movie_id = rm.movie_id
    GROUP BY 
        ca.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    am.total_actors
FROM 
    RankedMovies rm
JOIN 
    ActorMovies am ON rm.movie_id = am.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    am.total_actors DESC;
