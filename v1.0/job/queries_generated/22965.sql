WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.id AS actor_id,
        ca.person_id,
        ca.movie_id,
        c.name AS actor_name,
        1 AS level
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name c ON c.person_id = ca.person_id
    WHERE 
        c.name IS NOT NULL
    UNION ALL
    SELECT 
        ca.id,
        ca.person_id,
        m.movie_id,
        c2.name AS actor_name,
        a.level + 1
    FROM 
        cast_info ca
    INNER JOIN 
        movie_companies mc ON mc.movie_id = ca.movie_id
    INNER JOIN 
        movie_keyword mk ON mk.movie_id = mc.movie_id
    INNER JOIN 
        title m ON m.id = mc.movie_id
    INNER JOIN 
        aka_name c2 ON c2.person_id = ca.person_id
    JOIN 
        actor_hierarchy a ON a.movie_id = mc.movie_id
    WHERE 
        c2.name IS NOT NULL AND 
        a.level < 5
), top_movies AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ca.person_id) > 5
), ranked_movies AS (
    SELECT 
        movie_title,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        top_movies
)
SELECT 
    t.title,
    t.production_year,
    t.kind_id,
    ph.actor_id,
    ph.actor_name,
    ph.level,
    COALESCE(m.movie_title, 'No Movie') AS related_movie,
    CASE 
        WHEN ph.level <= 2 THEN 'Main Cast'
        WHEN ph.level BETWEEN 3 AND 4 THEN 'Supporting Cast'
        ELSE 'Cameo'
    END AS cast_role,
    IFNULL(kw.keyword, 'Unknown') AS associated_keyword
FROM 
    actor_hierarchy ph
LEFT JOIN 
    ranked_movies m ON m.movie_title = (SELECT title FROM ranked_movies ORDER BY rank LIMIT 1)
LEFT JOIN 
    movie_keyword kw ON kw.movie_id = ph.movie_id
INNER JOIN 
    title t ON t.id = ph.movie_id
WHERE 
    t.production_year >= 2000
    AND (ph.actor_name IS NOT NULL OR ph.actor_id IS NOT NULL)
ORDER BY 
    t.production_year DESC, rank ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
