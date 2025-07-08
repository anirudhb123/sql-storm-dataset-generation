
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        m.name AS production_company,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, m.name
),
top_casted_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        production_company,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rn = 1
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tcm.movie_id,
    tcm.movie_title,
    tcm.production_year,
    tcm.production_company,
    tcm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords
FROM 
    top_casted_movies tcm
LEFT JOIN 
    movie_keywords mk ON tcm.movie_id = mk.movie_id
ORDER BY 
    tcm.cast_count DESC;
