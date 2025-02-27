WITH movie_details AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        COUNT(DISTINCT mc.company_id) AS production_company_count, 
        AVG(COALESCE(mi.info::numeric, 0)) AS avg_info_score
    FROM 
        aka_title tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    WHERE 
        tm.production_year IS NOT NULL
    GROUP BY 
        tm.title, tm.production_year
),
actor_details AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movies_played,
        SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
)
SELECT 
    md.title,
    md.production_year,
    md.production_company_count,
    md.avg_info_score,
    ad.actor_name,
    ad.movies_played,
    ad.lead_roles
FROM 
    movie_details md
FULL OUTER JOIN 
    actor_details ad ON md.production_company_count > 0 AND ad.movies_played > 0
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, ad.movies_played DESC
LIMIT 50;
