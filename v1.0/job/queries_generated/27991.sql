WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000 
        AND t.production_year <= 2023
        AND a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name, r.role, k.keyword
),
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actor_name) DESC) AS actor_rank
    FROM 
        movie_details
    GROUP BY 
        title, production_year, actor_name, actor_role, movie_keyword
)
SELECT 
    production_year, 
    title, 
    actor_name, 
    actor_role, 
    movie_keyword, 
    production_companies
FROM 
    ranked_movies
WHERE 
    actor_rank <= 3
ORDER BY 
    production_year DESC, actor_rank;
