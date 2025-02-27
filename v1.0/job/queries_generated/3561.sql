WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(cc.person_id) AS actor_count,
        MAX(CASE WHEN cc.nr_order = 1 THEN 'Lead Actor' ELSE 'Supporting Actor' END) AS role_type
    FROM 
        cast_info cc
    JOIN 
        aka_name a ON cc.person_id = a.person_id
    JOIN 
        aka_title t ON cc.movie_id = t.movie_id
    GROUP BY 
        a.name, t.title, t.production_year
),
combined AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        am.actor_name,
        am.actor_count,
        am.role_type
    FROM 
        ranked_titles rt
    LEFT JOIN 
        actor_movie am ON rt.title_id = am.movie_title
    WHERE 
        rt.rank <= 5
)
SELECT 
    c.actor_name,
    COUNT(DISTINCT c.title_id) AS movies_count,
    ARRAY_AGG(DISTINCT c.title) FILTER (WHERE c.role_type = 'Lead Actor') AS lead_roles,
    SUM(CASE WHEN c.actor_count > 1 THEN 1 ELSE 0 END) AS supporting_roles,
    CASE 
        WHEN COUNT(DISTINCT c.title_id) > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Actor' 
    END AS actor_status
FROM 
    combined c
GROUP BY 
    c.actor_name
HAVING 
    SUM(CASE WHEN c.actor_count > 1 THEN 1 ELSE 0 END) > 5
ORDER BY 
    movies_count DESC;
