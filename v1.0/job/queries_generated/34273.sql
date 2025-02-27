WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.production_year AS original_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.linked_movie_id,
        m2.title,
        m2.production_year,
        mh.original_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.original_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY mh.movie_id) AS num_actors,
    CASE 
        WHEN mw.info IS NOT NULL THEN mw.info
        ELSE 'No additional info'
    END AS additional_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info mw ON t.id = mw.movie_id AND mw.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (t.production_year > 2000 OR mh.original_year IS NOT NULL)
GROUP BY 
    actor_name, t.title, mh.original_year, mw.info
ORDER BY 
    num_actors DESC, original_year DESC;
