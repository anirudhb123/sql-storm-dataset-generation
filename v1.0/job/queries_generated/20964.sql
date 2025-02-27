WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(1000)) AS path
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(1000)) AS path
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
actor_role_performance AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS appearance_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.id) DESC) AS role_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, a.name, r.role
),
average_screen_time AS (
    SELECT 
        m.movie_id,
        AVG(m.movie_time) AS avg_time
    FROM (
        SELECT 
            c.movie_id, 
            EXTRACT(EPOCH FROM (m.production_year * interval '1 year')) AS movie_time
        FROM complete_cast c
        JOIN aka_title m ON m.id = c.movie_id
        WHERE m.production_year IS NOT NULL
    ) AS m
    GROUP BY m.movie_id
),
final_performance AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ar.actor_name,
        ar.role_name,
        ar.appearance_count,
        ast.avg_time,
        CASE 
            WHEN ar.appearance_count > 5 THEN 'Frequent'
            ELSE 'Occasional'
        END AS actor_frequency,
        NULLIF(ar.appearance_count, 0) AS appearance_non_zero
    FROM movie_hierarchy mh
    LEFT JOIN actor_role_performance ar ON mh.movie_id = ar.movie_id
    LEFT JOIN average_screen_time ast ON mh.movie_id = ast.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.role_name,
    f.appearance_count,
    f.avg_time,
    f.actor_frequency,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM final_performance f
LEFT JOIN movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
WHERE 
    (f.avg_time IS NULL OR f.avg_time > 60)
    AND (f.actor_frequency = 'Frequent' OR f.role_name LIKE '%Lead%')
ORDER BY f.production_year, f.appearance_count DESC;
