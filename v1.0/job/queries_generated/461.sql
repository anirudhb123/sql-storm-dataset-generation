WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
top_cast AS (
    SELECT 
        c.movie_id,
        ci.person_id,
        COUNT(*) AS num_roles
    FROM cast_info ci
    JOIN complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN comp_cast_type cct ON ci.person_role_id = cct.id
    GROUP BY c.movie_id, ci.person_id
    HAVING COUNT(*) > 1
),
combined_info AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cn.name, 'Unknown') AS company_name,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        nt.keyword AS movie_keyword
    FROM ranked_titles t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword nt ON mk.keyword_id = nt.id
    WHERE t.rn = 1
)
SELECT 
    ci.subject_id,
    c.num_roles,
    ci.movie_id,
    ci.status_id,
    CONCAT(ci.subject_id, ' - ', ci.movie_id) AS subject_movie,
    CASE 
        WHEN ci.status_id IS NULL THEN 'Pending'
        ELSE 'Completed'
    END AS completion_status,
    COUNT(DISTINCT kv.movie_keyword) AS keyword_count
FROM complete_cast ci
JOIN top_cast c ON ci.movie_id = c.movie_id
LEFT JOIN combined_info kv ON ci.movie_id = kv.title_id
GROUP BY ci.subject_id, c.num_roles, ci.movie_id, ci.status_id
HAVING COUNT(DISTINCT kv.movie_keyword) > 0
ORDER BY ci.movie_id DESC;
