WITH RECURSIVE cte_movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id, 
        et.title AS movie_title, 
        cte.movie_id AS parent_movie_id,
        cte.level + 1
    FROM 
        aka_title et
    JOIN 
        cte_movie_hierarchy cte ON et.episode_of_id = cte.movie_id
)
SELECT 
    m.id AS movie_id, 
    m.title AS movie_title,
    COALESCE(c.name, 'Unknown') AS character_name,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(mi.info) AS movie_info,
    SUM(CASE WHEN c.note IS NULL THEN 0 ELSE 1 END) AS cast_note_count,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    cte_movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    m.level <= 2
    AND m.movie_id IS NOT NULL
    AND a.gender IS NULL
GROUP BY 
    m.id, m.title, c.name, a.name
ORDER BY 
    keyword_count DESC, m.production_year DESC;
