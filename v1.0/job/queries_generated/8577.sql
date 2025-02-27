WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        c.name AS company_name, 
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorDetails AS (
    SELECT 
        ak.id AS aka_id, 
        ak.name AS actor_name,
        pi.info AS actor_info
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
),
CompleteDetails AS (
    SELECT 
        md.title, 
        md.production_year, 
        ad.actor_name, 
        ad.actor_info, 
        md.company_name, 
        md.movie_keyword
    FROM 
        MovieDetails md
    JOIN 
        cast_info ci ON md.title_id = ci.movie_id
    JOIN 
        ActorDetails ad ON ci.person_id = ad.aka_id
)

SELECT 
    title, 
    production_year, 
    actor_name, 
    actor_info, 
    company_name, 
    movie_keyword
FROM 
    CompleteDetails
ORDER BY 
    production_year DESC, title;
