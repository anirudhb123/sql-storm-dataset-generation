
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        ActorDetails
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    ta.actor_name,
    ta.movie_count
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON ci.movie_id = md.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    TopActors ta ON ta.actor_name = a.name
ORDER BY 
    md.production_year DESC, 
    ta.movie_count DESC;
