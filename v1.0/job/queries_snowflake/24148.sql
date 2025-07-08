
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_names AS (
    SELECT 
        ak.person_id,
        LISTAGG(ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS full_name
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
),
movie_details AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN ki.keyword LIKE '%Action%' THEN 1 ELSE 0 END) AS has_action,
        MAX(CASE WHEN ki.keyword LIKE '%Comedy%' THEN 1 ELSE 0 END) AS has_comedy
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(r.role) AS main_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.title_rank,
    a.full_name AS actor_names,
    m.company_count,
    CASE 
        WHEN m.has_action = 1 AND m.has_comedy = 1 THEN 'Action-Comedy'
        WHEN m.has_action = 1 THEN 'Action Only'
        WHEN m.has_comedy = 1 THEN 'Comedy Only'
        ELSE 'Other'
    END AS genre_indicator,
    cs.actor_count,
    cs.main_role
FROM 
    ranked_titles r
JOIN 
    movie_details m ON r.title = m.title AND r.production_year = m.production_year
LEFT JOIN 
    cast_summary cs ON m.movie_id = cs.movie_id
LEFT JOIN 
    actor_names a ON cs.actor_count > 0 AND cs.movie_id = m.movie_id
WHERE 
    r.title_rank <= 10
ORDER BY 
    r.production_year DESC, r.title_rank;
