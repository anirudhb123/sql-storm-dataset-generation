WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year AS year,
        c.name AS company_name,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        role_type r ON cc.person_role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000 
        AND c.country_code = 'USA'
),
aggregated_stats AS (
    SELECT 
        year,
        COUNT(DISTINCT movie_title) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors,
        COUNT(DISTINCT company_name) AS total_companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_data
    GROUP BY 
        year
)
SELECT 
    year,
    total_movies,
    total_actors,
    total_companies,
    keywords
FROM 
    aggregated_stats
ORDER BY 
    year DESC;
