WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        c.name AS actor_name,
        rt.role,
        COUNT(ci.id) AS role_count,
        DENSE_RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.id) DESC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, c.name, rt.role
),
complete_cast_summary AS (
    SELECT 
        cm.movie_id,
        COUNT(DISTINCT cm.subject_id) AS total_actors,
        COUNT(DISTINCT cm.status_id) AS active_status_count
    FROM 
        complete_cast cm
    GROUP BY 
        cm.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    cr.actor_name,
    cr.role,
    cr.role_count,
    ccs.total_actors,
    ccs.active_status_count
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_roles cr ON rm.movie_id = cr.movie_id AND cr.role_rank <= 3 
LEFT JOIN 
    complete_cast_summary ccs ON rm.movie_id = ccs.movie_id
WHERE 
    (ccs.total_actors IS NOT NULL OR cr.role_count > 2) 
    AND (rm.year_rank <= 5 OR rm.production_year = 2023) 
ORDER BY 
    rm.production_year DESC, 
    cr.role_count DESC, 
    cr.actor_name;