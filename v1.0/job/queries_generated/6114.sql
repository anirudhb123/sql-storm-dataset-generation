WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        a.name AS actor_name,
        cnt.name AS company_name,
        kt.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cnt ON cnt.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kt ON kt.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000 AND 
        ci.nr_order < 5
), aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_data
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    companies,
    keywords
FROM 
    aggregated_data
ORDER BY 
    production_year DESC, movie_title ASC
LIMIT 100;
