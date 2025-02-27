WITH actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        string_agg(DISTINCT ci.kind, ', ') AS company_types
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.id, a.name, t.title, t.production_year, t.kind_id
),
ranked_movies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year,
        kind_id,
        keywords,
        company_types,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS movie_rank
    FROM 
        actor_movie_info
)
SELECT 
    actor_id,
    actor_name,
    movie_title,
    production_year,
    keywords,
    company_types
FROM 
    ranked_movies
WHERE 
    movie_rank <= 5
ORDER BY 
    actor_id, production_year DESC;
