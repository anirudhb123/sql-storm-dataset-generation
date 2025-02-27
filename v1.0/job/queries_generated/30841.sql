WITH RECURSIVE title_hierarchy AS (
    -- Recursive CTE to fetch titles and their parent episode relationships
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS depth
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        th.depth + 1 AS depth
    FROM 
        title_hierarchy th
    JOIN 
        title t ON th.title_id = t.episode_of_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(m.title) AS linked_movie,
    AVG(CASE WHEN pc.info IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS has_person_info,
    SUM(COALESCE(mc.company_id, 0)) AS total_companies,
    CASE 
        WHEN th.depth IS NULL THEN 'Standalone Movie' 
        ELSE 'Episode of a Series'
    END AS title_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    person_info pc ON a.person_id = pc.person_id
LEFT JOIN 
    title_hierarchy th ON t.id = th.title_id
GROUP BY 
    a.id, t.title, t.production_year, th.depth
ORDER BY 
    keyword_count DESC, t.production_year DESC;
