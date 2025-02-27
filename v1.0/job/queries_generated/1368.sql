WITH movie_details AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        movie_details
),
top_cast AS (
    SELECT 
        DISTINCT cn.name AS company_name,
        cnt.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cnt ON mc.company_type_id = cnt.id
    WHERE 
        cn.country_code IS NOT NULL 
        AND cn.name IS NOT NULL
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tc.company_name,
    tc.company_type
FROM 
    top_movies tm
INNER JOIN 
    top_cast tc ON tm.movie_id = tc.movie_id
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
