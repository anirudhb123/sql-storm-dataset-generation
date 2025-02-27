WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
filtered_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(ci.role_id) AS total_roles
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NULL OR ci.note LIKE '%lead%'
    GROUP BY 
        ci.movie_id, ci.person_id
),
movie_details AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(mk.keyword_id), 0) AS total_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
final_results AS (
    SELECT 
        rt.production_year,
        rt.title,
        rt.year_rank,
        fc.total_roles,
        md.total_keywords,
        COALESCE(fc.total_roles, 0) * COALESCE(md.total_keywords, 1) AS interaction_score
    FROM 
        ranked_titles rt
    LEFT JOIN 
        filtered_cast fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        movie_details md ON rt.title_id = md.movie_id
    WHERE 
        rt.year_rank <= 5
        AND (md.total_keywords IS NULL OR md.total_keywords >= 3)
)

SELECT 
    production_year,
    title,
    year_rank,
    total_roles,
    total_keywords,
    interaction_score,
    CASE 
        WHEN interaction_score < 10 THEN 'Low Interaction'
        WHEN interaction_score BETWEEN 10 AND 30 THEN 'Medium Interaction'
        ELSE 'High Interaction'
    END AS interaction_category
FROM 
    final_results
WHERE 
    (total_roles IS NULL OR total_roles > 0)
ORDER BY 
    production_year DESC, interaction_score DESC
LIMIT 50;