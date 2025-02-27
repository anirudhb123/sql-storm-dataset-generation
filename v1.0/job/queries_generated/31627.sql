WITH RECURSIVE movie_path AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS depth
    FROM 
        aka_title t
        JOIN title m ON t.movie_id = m.id
    WHERE 
        m.production_year = 2020

    UNION ALL

    SELECT 
        mp.movie_id,
        t.title,
        mp.depth + 1
    FROM 
        movie_link ml
        JOIN movie_path mp ON ml.movie_id = mp.movie_id
        JOIN title t ON ml.linked_movie_id = t.id
    WHERE 
        mp.depth < 5
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COALESCE(c.role_id, 0) AS role_id,
    AVG(mk.count) AS average_keyword_count,
    SUM(i.info) AS total_info_count
FROM 
    aka_name a
    LEFT JOIN cast_info c ON a.person_id = c.person_id
    LEFT JOIN aka_title at ON c.movie_id = at.movie_id
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN movie_info i ON at.movie_id = i.movie_id
    JOIN movie_path mp ON at.id = mp.movie_id
WHERE 
    a.name IS NOT NULL
    AND (c.role_id IS NULL OR c.role_id <> 0)
    AND (mp.depth < 3 OR mp.depth IS NULL)
GROUP BY 
    a.name,
    t.title,
    c.role_id
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 5
ORDER BY 
    actor_name, 
    average_keyword_count DESC;
