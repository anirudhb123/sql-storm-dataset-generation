WITH movie_details AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        COALESCE(SUM(CASE WHEN cn.country_code IS NOT NULL THEN 1 ELSE 0 END), 0) AS country_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS actor_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info cc ON at.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        at.id, at.title, at.production_year
),
high_actor_count_movies AS (
    SELECT 
        title_id, title, production_year, actor_count, country_count, company_names
    FROM
        movie_details
    WHERE 
        actor_count > (SELECT AVG(actor_count) FROM movie_details)
        AND production_year IS NOT NULL
),
top_company_movies AS (
    SELECT 
        at.title,
        COUNT(DISTINCT co.name) AS unique_companies
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code IS NOT NULL
    GROUP BY 
        at.title
),

final_report AS (
    SELECT 
        h.title AS movie_title,
        h.production_year,
        h.actor_count,
        h.country_count,
        h.company_names,
        COALESCE(t.unique_companies, 0) AS unique_company_count
    FROM 
        high_actor_count_movies h
    LEFT JOIN 
        top_company_movies t ON h.title = t.title
)

SELECT 
    fr.movie_title,
    fr.production_year,
    fr.actor_count,
    fr.country_count,
    fr.company_names,
    fr.unique_company_count
FROM 
    final_report fr
WHERE 
    fr.actor_count IS NOT NULL
    AND fr.unique_company_count > 2
ORDER BY 
    fr.actor_count DESC, fr.production_year DESC
LIMIT 100;