WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
        AND k.keyword IS NOT NULL
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    ARRAY_AGG(DISTINCT md.movie_keyword) AS keywords,
    STRING_AGG(DISTINCT CONCAT(md.actor_name, ' (', md.actor_role, ')'), ', ') AS actors
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
