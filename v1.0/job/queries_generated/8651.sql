WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
),
info_aspect AS (
    SELECT 
        md.movie_id,
        COUNT(DISTINCT md.company_name) AS num_companies,
        COUNT(DISTINCT md.movie_keyword) AS num_keywords,
        COUNT(DISTINCT md.actor_name) AS num_actors
    FROM 
        movie_details md
    GROUP BY 
        md.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ia.num_companies,
    ia.num_keywords,
    ia.num_actors
FROM 
    movie_details md
JOIN 
    info_aspect ia ON md.movie_id = ia.movie_id
ORDER BY 
    md.production_year DESC, 
    ia.num_actors DESC, 
    ia.num_companies DESC
LIMIT 50;
