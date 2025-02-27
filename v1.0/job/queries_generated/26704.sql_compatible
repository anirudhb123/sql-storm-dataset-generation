
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorDetails AS (
    SELECT 
        a.person_id AS person_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.person_id, a.name
),
CompleteMovieDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        ad.actor_name,
        ad.roles
    FROM 
        MovieDetails md
    LEFT JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    LEFT JOIN 
        ActorDetails ad ON ci.person_id = ad.person_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    STRING_AGG(DISTINCT CONCAT(actor_name, ' (', roles, ')'), '; ') AS actor_details
FROM 
    CompleteMovieDetails
GROUP BY 
    movie_id, title, production_year, keywords
ORDER BY 
    production_year DESC, title;
