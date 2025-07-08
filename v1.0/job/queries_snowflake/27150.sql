
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%' 
        OR k.keyword LIKE '%drama%'
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
TopActors AS (
    SELECT 
        ad.name,
        ad.total_movies,
        ROW_NUMBER() OVER (ORDER BY ad.total_movies DESC) AS actor_rank
    FROM 
        ActorDetails ad
)
SELECT 
    ta.name,
    ta.total_movies,
    ta.actor_rank,
    rm.title AS recent_movie
FROM 
    TopActors ta
JOIN 
    RankedMovies rm ON ta.actor_rank = 1
ORDER BY 
    ta.actor_rank;
