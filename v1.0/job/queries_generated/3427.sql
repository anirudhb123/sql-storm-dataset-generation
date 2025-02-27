WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        c.company_name,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        SUM(CASE WHEN ca.role_id IS NOT NULL THEN 1 ELSE 0 END) AS starring_actors
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        t.title, t.production_year, c.company_name
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_name,
        md.actor_count,
        md.starring_actors,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC, md.title) AS ranking
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.actor_count,
    rm.starring_actors
FROM 
    ranked_movies rm
WHERE 
    rm.ranking <= 5 
    AND rm.production_year > 2000
ORDER BY 
    rm.production_year ASC, 
    rm.actor_count DESC;
