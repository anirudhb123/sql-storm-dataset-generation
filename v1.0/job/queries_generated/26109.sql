WITH movie_summary AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT c.name SEPARATOR ', '), 'None') AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        ctype.kind AS company_type,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_role_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ctype ON mc.company_type_id = ctype.id
    GROUP BY 
        a.id, t.title, t.production_year, ctype.kind
),
top_movies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_names,
        ms.keyword_count,
        ms.company_type,
        ms.cast_role_count,
        RANK() OVER (ORDER BY ms.keyword_count DESC, ms.production_year DESC) AS ranking
    FROM 
        movie_summary ms
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    tm.keyword_count,
    tm.company_type,
    tm.cast_role_count
FROM 
    top_movies tm
WHERE 
    tm.ranking <= 10
ORDER BY 
    tm.keyword_count DESC, tm.production_year DESC;
