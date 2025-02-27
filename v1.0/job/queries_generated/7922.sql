WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
),
ProductionDetails AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_title) AS total_movies,
        SUM(movie_count) AS total_actors
    FROM 
        MovieDetails md
    JOIN 
        ActorCount ac ON md.actor_name = ac.actor_name
    GROUP BY 
        production_year
)
SELECT 
    pd.production_year,
    pd.total_movies,
    pd.total_actors,
    COALESCE(pd.total_movies::float / NULLIF(pd.total_actors, 0), 0) AS avg_movies_per_actor
FROM 
    ProductionDetails pd
ORDER BY 
    pd.production_year DESC;
