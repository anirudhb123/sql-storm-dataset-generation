
WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
), 
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        company_counts cc ON t.id = cc.movie_id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    fm.production_year,
    fm.company_count
FROM 
    ranked_titles rt
JOIN 
    filtered_movies fm ON rt.movie_title = fm.title AND rt.production_year = fm.production_year
WHERE 
    rt.rank = 1
ORDER BY 
    fm.production_year DESC, 
    rt.actor_name
LIMIT 10;
