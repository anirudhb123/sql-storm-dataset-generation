WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        CAST(NULL AS INTEGER) AS parent_id,
        0 AS depth
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS title_id,
        e.title,
        e.production_year,
        e.kind_id,
        t.title_id AS parent_id,
        th.depth + 1
    FROM 
        title e
    JOIN 
        title_hierarchy th ON e.episode_of_id = th.title_id
)
SELECT 
    th.title AS episode_title,
    th.production_year AS episode_year,
    t.title AS parent_title,
    th.depth,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) ELSE 0 END) AS avg_person_info_length
FROM 
    title_hierarchy th
LEFT JOIN 
    aka_title t ON t.id = th.parent_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = th.title_id
LEFT JOIN 
    cast_info c ON c.movie_id = th.title_id
LEFT JOIN 
    person_info p ON p.person_id = c.person_id
WHERE 
    th.depth <= 2
GROUP BY 
    th.title, th.production_year, t.title, th.depth
ORDER BY 
    th.depth DESC, actor_count DESC
LIMIT 100
OFFSET 10;  -- Skipping the first 10 rows to simulate pagination

-- Additional metrics for performance benchmarking
WITH actors AS (
    SELECT 
        c.person_id,
        COUNT(cc.movie_id) AS movie_count,
        SUM(CASE WHEN p.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_entries
    FROM 
        cast_info c
    LEFT JOIN 
        person_info p ON p.person_id = c.person_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = c.movie_id
    GROUP BY 
        c.person_id
),
info_summary AS (
    SELECT 
        info_type_id,
        COUNT(*) AS total_info_count
    FROM 
        person_info 
    GROUP BY 
        info_type_id
)
SELECT 
    a.person_id,
    a.movie_count,
    a.info_entries,
    COALESCE(i.total_info_count, 0) AS total_info_count
FROM 
    actors a
LEFT JOIN 
    info_summary i ON i.info_type_id = a.info_entries
WHERE 
    a.movie_count > 5 AND a.info_entries IS NOT NULL
ORDER BY 
    a.movie_count DESC, a.person_id
FETCH FIRST 50 ROWS ONLY;
