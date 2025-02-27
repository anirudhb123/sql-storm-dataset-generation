WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        cast,
        keywords,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    movie_title,
    production_year,
    cast,
    keywords,
    company_count
FROM 
    top_movies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
