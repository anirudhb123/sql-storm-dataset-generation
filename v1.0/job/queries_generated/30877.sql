WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    AVG(CASE WHEN m.production_year < 2010 THEN 1 ELSE 0 END) AS avg_before_2010,
    MAX(m.production_year) AS latest_movie_year,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
AND 
    a.name <> ''
AND 
    a.name NOT LIKE '%test%'
GROUP BY 
    a.name
HAVING 
    COUNT(c.movie_id) > 10
ORDER BY 
    total_movies DESC, actor_rank ASC;
