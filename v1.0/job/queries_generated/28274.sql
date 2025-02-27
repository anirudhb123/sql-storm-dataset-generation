WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        a.kind_id,
        k.keyword AS movie_keyword
    FROM 
        aka_title AS a
    JOIN 
        movie_companies AS mc ON a.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
ActorDetails AS (
    SELECT 
        p.name AS actor_name,
        r.role AS role_name,
        a.movie_id,
        a.nr_order
    FROM 
        cast_info AS a
    JOIN 
        aka_name AS p ON a.person_id = p.person_id
    JOIN 
        role_type AS r ON a.role_id = r.id
)
SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(DISTINCT ad.actor_name || ' (' || ad.role_name || ')', ', ') AS cast,
    STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails AS md
LEFT JOIN 
    ActorDetails AS ad ON md.id = ad.movie_id
GROUP BY 
    md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
