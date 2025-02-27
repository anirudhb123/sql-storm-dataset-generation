WITH movie_details AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        p.info AS person_info
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
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        ci.nr_order < 5
        AND t.production_year >= 2000
        AND c.kind IN ('Distributor', 'Production Company')
),
aggregated_movie_info AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        STRING_AGG(movie_keyword, ', ') AS keywords_collected,
        STRING_AGG(DISTINCT company_type, ', ') AS companies_involved
    FROM 
        movie_details
    GROUP BY 
        actor_name, movie_title, production_year
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords_collected,
    companies_involved
FROM 
    aggregated_movie_info
ORDER BY 
    production_year DESC, actor_name;
