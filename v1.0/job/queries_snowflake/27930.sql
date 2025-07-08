WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        COUNT(c.id) AS cast_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        a.name, t.title, t.production_year, ct.kind
),
ActorMovieDetails AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        company_type,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS rank
    FROM 
        ActorMovies
)
SELECT 
    AMD.actor_name,
    AMD.movie_title,
    AMD.production_year,
    AMD.company_type,
    AMD.cast_count
FROM 
    ActorMovieDetails AMD
WHERE 
    AMD.rank <= 5
ORDER BY 
    AMD.actor_name, AMD.production_year DESC;