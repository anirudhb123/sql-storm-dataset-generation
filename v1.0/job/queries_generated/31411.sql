WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    AVG(r.role_id) AS avg_role_id,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c.name, ', ') AS companies_involved,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY l.link_type_id DESC) AS row_num
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_link l ON m.id = l.movie_id
WHERE 
    a.name IS NOT NULL
    AND m.production_year > 2000
    AND m.id IN (SELECT movie_id FROM complete_cast WHERE status_id = 1)
    AND EXISTS (SELECT 1 FROM movie_info WHERE movie_id = m.id AND info_type_id = (SELECT id FROM info_type WHERE info = 'Awards'))
GROUP BY 
    a.name, m.title
HAVING 
    keyword_count > 0
ORDER BY 
    avg_role_id DESC, actor_name ASC;
