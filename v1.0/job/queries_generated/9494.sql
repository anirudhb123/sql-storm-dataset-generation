WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        r.role AS role,
        p.info AS biography
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        person_info p ON a.person_id = p.person_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    ad.actor_name,
    ad.role,
    ad.biography,
    COUNT(mk.movie_id) AS keyword_count
FROM 
    MovieDetails md
JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
JOIN 
    ActorDetails ad ON md.movie_id = ad.actor_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
WHERE 
    mi.info LIKE '%award%'
GROUP BY 
    md.movie_title, md.production_year, md.movie_keyword, ad.actor_name, ad.role, ad.biography
ORDER BY 
    md.production_year DESC, keyword_count DESC;
