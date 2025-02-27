WITH RECURSIVE movie_hierarchy AS (
    -- This CTE retrieves all descendant movies recursively from a starting movie
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.id = (SELECT id FROM aka_title WHERE title = 'Inception')  -- Starting movie
    
    UNION ALL
    
    SELECT 
        linked.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link linked
    JOIN 
        aka_title t ON linked.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON linked.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info::numeric
            ELSE NULL 
        END) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rn,
    COALESCE(c.kind, 'Not Specified') AS company_kind,
    RANK() OVER (ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS keyword_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
INNER JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id 
LEFT JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Rating', 'Box Office'))
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 3
ORDER BY 
    actor_name, movie_title;
