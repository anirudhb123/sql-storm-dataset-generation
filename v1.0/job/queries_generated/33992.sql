WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN 
        title t ON m.movie_id = t.id
)

SELECT
    a.name AS actor_name,
    count(DISTINCT c.movie_id) AS movies_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    AVG(mh.production_year) AS average_production_year,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY count(DISTINCT c.movie_id) DESC) AS rank,
    CASE 
        WHEN AVG(mh.production_year) IS NULL THEN 'No productions'
        ELSE 'Has productions'
    END AS production_status
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    a.name IS NOT NULL AND 
    (mh.production_year > 1999 OR mh.production_year IS NULL)
GROUP BY 
    a.name, a.person_id
HAVING 
    count(DISTINCT c.movie_id) > 5
ORDER BY 
    rank;
