
WITH ActorMovies AS (
    SELECT 
        ca.person_id AS actor_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name an ON ca.person_id = an.person_id
    INNER JOIN 
        complete_cast cc ON ca.movie_id = cc.movie_id
    GROUP BY 
        ca.person_id
),
TopActors AS (
    SELECT 
        actor_id,
        movie_count
    FROM 
        ActorMovies
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        an.name AS actor_name
    FROM 
        title t
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.person_id IN (SELECT actor_id FROM TopActors)
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors
FROM 
    MovieDetails md
GROUP BY 
    md.movie_title, md.production_year, md.company_type
ORDER BY 
    md.production_year DESC, md.movie_title;
