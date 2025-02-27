WITH movie_stats AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        COUNT(DISTINCT k.keyword) AS num_keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
)
SELECT 
    movie_title,
    production_year,
    num_actors,
    num_keywords,
    companies
FROM 
    movie_stats
WHERE 
    num_actors > 5
ORDER BY 
    production_year DESC, num_actors DESC
LIMIT 10;
