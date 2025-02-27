
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
        th.title_id AS parent_id,
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
    AVG(COALESCE(LENGTH(p.info), 0)) AS avg_person_info_length
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
OFFSET 10;
