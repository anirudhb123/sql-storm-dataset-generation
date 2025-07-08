
WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actor_names,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        company_names,
        keywords,
        RANK() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    movie_title,
    production_year,
    actor_names,
    company_names,
    keywords
FROM 
    top_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
