WITH MovieOverview AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        m.name AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
)
SELECT 
    actor_id,
    actor_name,
    movie_title,
    production_year,
    actor_role,
    company_name,
    ARRAY_AGG(movie_keyword) AS keywords
FROM 
    MovieOverview
WHERE 
    role_rank <= 3
GROUP BY 
    actor_id, actor_name, movie_title, production_year, actor_role, company_name
ORDER BY 
    actor_name, production_year DESC;