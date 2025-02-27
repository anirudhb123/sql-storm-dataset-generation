WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        kt.keyword AS movie_keyword,
        a.name AS actor_name,
        p.gender
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND kt.keyword LIKE '%drama%'
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.movie_keyword,
        md.actor_name,
        md.gender,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.title) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.movie_keyword,
    rm.actor_name,
    rm.gender
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank;
