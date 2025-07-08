WITH MovieDetails AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        a.name, t.title, t.production_year, c.kind
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    md.actor_name,
    md.movie_title,
    md.production_year,
    md.company_type,
    md.keywords,
    ac.movie_count
FROM 
    MovieDetails md
JOIN 
    ActorCount ac ON md.actor_name = ac.actor_name
ORDER BY 
    ac.movie_count DESC, md.production_year DESC;
