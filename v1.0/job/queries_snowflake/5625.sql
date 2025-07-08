WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mi.info_type_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ac.actor_count,
    cc.company_count
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_counts ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    company_counts cc ON rt.title_id = cc.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year, rt.rank;
