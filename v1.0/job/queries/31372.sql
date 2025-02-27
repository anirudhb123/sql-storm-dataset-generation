
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        h.level + 1
    FROM 
        movie_link l
    JOIN 
        movie_hierarchy h ON l.linked_movie_id = h.movie_id
    JOIN 
        aka_title m ON l.movie_id = m.id
    WHERE 
        h.level < 3
),

cast_contributions AS (
    SELECT 
        c.person_id,
        COUNT(c.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT c.movie_id) AS movies
    FROM 
        cast_info c
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.person_id
)

SELECT 
    n.name AS actor_name,
    n.gender,
    COUNT(DISTINCT mh.movie_id) AS movies_as_lead,
    SUM(CASE WHEN c.role_id = 1 THEN 1 ELSE 0 END) AS lead_role_count,
    AVG(mh.level) AS avg_movie_level,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    name n
LEFT JOIN 
    cast_info c ON n.id = c.person_id
LEFT JOIN 
    (SELECT * FROM movie_hierarchy WHERE movie_id IS NOT NULL) mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    n.gender IS NOT NULL
GROUP BY 
    n.id, n.name, n.gender
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    lead_role_count DESC, avg_movie_level ASC
LIMIT 10;
