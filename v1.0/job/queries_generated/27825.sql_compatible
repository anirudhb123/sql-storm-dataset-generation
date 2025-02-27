
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id DESC) AS ranking
    FROM 
        aka_title mt
    INNER JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%award%'
),

ActorMovies AS (
    SELECT 
        ca.person_id,
        ak.name AS actor_name,
        rm.movie_id,
        rm.movie_title
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    INNER JOIN 
        RankedMovies rm ON ca.movie_id = rm.movie_id
),

DistinctActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        ActorMovies
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_id) > 1
)

SELECT 
    d.actor_name,
    d.movie_count,
    STRING_AGG(a.movie_title, ', ') AS movies
FROM 
    DistinctActors d
JOIN 
    ActorMovies a ON d.actor_name = a.actor_name
GROUP BY 
    d.actor_name, d.movie_count
ORDER BY 
    d.movie_count DESC;
