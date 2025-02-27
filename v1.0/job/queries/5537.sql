WITH movie_data AS (
    SELECT 
        t.title, 
        t.production_year, 
        k.keyword, 
        c.name AS company_name, 
        p.info AS director_info
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    WHERE 
        t.production_year > 2000
),
aggregated_data AS (
    SELECT 
        production_year, 
        COUNT(title) AS total_movies, 
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        movie_data
    GROUP BY 
        production_year
)
SELECT 
    ad.production_year, 
    ad.total_movies, 
    ad.keywords, 
    (SELECT COUNT(*) FROM company_name WHERE country_code = 'USA') AS total_us_companies
FROM 
    aggregated_data ad
ORDER BY 
    ad.production_year DESC;
