WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name ASC) AS cast_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword ASC) AS keywords,
        c.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type c ON c.id = mc.company_type_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_names,
        keywords,
        company_type,
        RANK() OVER (PARTITION BY production_year ORDER BY production_year DESC) AS year_rank
    FROM 
        movie_details
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_names,
    keywords,
    company_type,
    year_rank
FROM 
    ranked_movies
WHERE 
    year_rank <= 10
ORDER BY 
    production_year DESC, movie_title ASC;
