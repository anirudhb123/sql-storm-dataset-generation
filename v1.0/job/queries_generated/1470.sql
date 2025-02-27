WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        (SELECT STRING_AGG(DISTINCT c.name, ', ') 
         FROM company_name c 
         JOIN movie_companies mc ON c.id = mc.company_id 
         WHERE mc.movie_id = m.id) AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
detailed_report AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        md.keyword,
        md.companies,
        CASE 
            WHEN rm.actor_count > 10 THEN 'Blockbuster'
            WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Moderate Success'
            ELSE 'Indie Film'
        END AS film_category
    FROM 
        ranked_movies rm
    JOIN 
        movie_details md ON rm.title = md.title AND rm.production_year = md.production_year
)
SELECT 
    title,
    production_year,
    actor_count,
    keyword,
    companies,
    film_category
FROM 
    detailed_report
WHERE 
    film_category != 'Indie Film'
ORDER BY 
    production_year DESC, actor_count DESC
LIMIT 50;
