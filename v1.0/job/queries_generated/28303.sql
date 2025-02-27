WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info AS ca ON m.id = ca.movie_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keywords,
        companies,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_desc
    FROM 
        movie_data
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.keywords,
    rm.companies
FROM 
    ranked_movies AS rm
WHERE 
    rm.rank_desc <= 10
ORDER BY 
    rm.rank_desc;
