WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
actor_movie_counts AS (
    SELECT 
        ci.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
), 
company_movie_counts AS (
    SELECT 
        mc.company_id, 
        COUNT(DISTINCT mc.movie_id) AS company_movie_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
)
SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    rt.title,
    rt.production_year,
    COALESCE(amc.movie_count, 0) AS actor_movie_count,
    COALESCE(cmc.company_movie_count, 0) AS company_movie_count,
    CASE 
        WHEN rt.year_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_info ci ON ci.movie_id = rt.title_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    actor_movie_counts amc ON amc.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rt.title_id
LEFT JOIN 
    company_movie_counts cmc ON cmc.company_id = mc.company_id
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    rt.production_year DESC, actor_movie_count DESC;
