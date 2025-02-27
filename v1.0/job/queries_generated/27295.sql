WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
        AND ak.name IS NOT NULL
),
ActorRankings AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        STRING_AGG(movie_title, ', ') AS movie_list
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
)
SELECT 
    ar.actor_name,
    ar.movie_count,
    ar.movie_list
FROM 
    ActorRankings ar
WHERE 
    ar.movie_count > 5
ORDER BY 
    ar.movie_count DESC;
