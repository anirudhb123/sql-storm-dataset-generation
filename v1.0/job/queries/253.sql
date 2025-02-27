
WITH movie_years AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.subject_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        my.movie_id,
        my.title,
        my.production_year,
        my.cast_count,
        RANK() OVER (PARTITION BY my.production_year ORDER BY my.cast_count DESC) AS rank
    FROM 
        movie_years my
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ai.name, 'Unknown') AS actor_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ai ON ci.person_id = ai.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, ai.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    tm.production_year DESC, tm.title;
