WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS year_rank
    FROM 
        title t
        JOIN complete_cast cc ON t.id = cc.movie_id
        JOIN cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
        JOIN aka_name a ON a.person_id = ci.person_id
        LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.* 
    FROM 
        ranked_movies rm 
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    COUNT(DISTINCT mc.company_id) AS company_count,
    ARRAY_AGG(DISTINCT cn.name) AS companies
FROM 
    top_movies tm
    LEFT JOIN movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_names
ORDER BY 
    tm.production_year DESC, company_count DESC;
