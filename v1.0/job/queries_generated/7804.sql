WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        p.gender AS actor_gender,
        r.role AS actor_role,
        t.title AS movie_title
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_title t ON ci.movie_id = t.id
), CombinedDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_type,
        md.movie_keyword,
        ad.actor_name,
        ad.actor_gender,
        ad.actor_role
    FROM 
        MovieDetails md
    JOIN 
        ActorDetails ad ON md.movie_title = ad.movie_title
)
SELECT 
    movie_title,
    production_year,
    company_type,
    movie_keyword,
    actor_name,
    actor_gender,
    actor_role
FROM 
    CombinedDetails
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, movie_title;
