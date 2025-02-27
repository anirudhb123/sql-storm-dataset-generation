WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
        CASE 
            WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Has Companies'
            ELSE 'No Companies'
        END AS company_status
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rank
    FROM 
        movie_details
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_names,
    keywords,
    company_status,
    rank
FROM 
    ranked_movies
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, rank
LIMIT 50;
