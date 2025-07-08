
WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year AS movie_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.movie_id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.name, a.id, m.id, m.title, m.production_year
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS movies_count
    FROM 
        ActorMovies
    GROUP BY 
        actor_name
    ORDER BY 
        movies_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year AS movie_year,
        co.name AS company_name,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT k.keyword) AS movie_keywords
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, co.name, ct.kind
)
SELECT 
    ta.actor_name,
    ta.movies_count,
    md.movie_title,
    md.movie_year,
    md.company_name,
    md.company_type,
    md.movie_keywords
FROM 
    TopActors ta
JOIN 
    ActorMovies am ON ta.actor_name = am.actor_name
JOIN 
    MovieDetails md ON am.movie_id = md.movie_id
ORDER BY 
    ta.movies_count DESC, am.movie_year DESC;
