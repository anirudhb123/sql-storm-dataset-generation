WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
),
castings AS (
    SELECT 
        c.movie_id,
        ca.name AS actor_name,
        ct.kind AS role_type,
        COUNT(*) AS role_count
    FROM cast_info c
    JOIN aka_name ca ON ca.person_id = c.person_id
    JOIN role_type ct ON ct.id = c.role_id
    GROUP BY c.movie_id, ca.name, ct.kind
),
movies_with_actors AS (
    SELECT 
        rt.title,
        rt.production_year,
        ca.actor_name,
        ca.role_type,
        rt.keyword_count
    FROM ranked_titles rt
    LEFT JOIN castings ca ON rt.id = ca.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(m.role_type, 'No Role') AS role_type,
    m.keyword_count,
    CASE 
        WHEN m.keyword_count > 5 THEN 'High'
        WHEN m.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_density
FROM movies_with_actors m
WHERE m.production_year > 2000
  AND (m.keyword_count IS NULL OR m.keyword_count > 0)
ORDER BY m.production_year DESC, m.title;
