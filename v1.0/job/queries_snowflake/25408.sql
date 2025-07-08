WITH actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        p.info AS person_biography,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS latest_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year > 2000
)

SELECT 
    actor_id,
    actor_name,
    movie_title,
    production_year,
    kind_id,
    company_type,
    movie_keyword,
    person_biography
FROM 
    actor_movie_info
WHERE 
    latest_movie_rank = 1
ORDER BY 
    production_year DESC, actor_name;
