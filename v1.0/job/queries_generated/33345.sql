WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year > 2000
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT c.id) AS total_cast_members,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
    AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) ELSE NULL END) AS avg_info_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    array_agg(DISTINCT COALESCE(comp.name, 'Independent')) AS company_names
FROM
    cast_info c
INNER JOIN 
    aka_name a ON c.person_id = a.person_id
INNER JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
INNER JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
INNER JOIN 
    keyword k ON mk.keyword_id = k.id
INNER JOIN 
    movie_hierarchy mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Biography', 'Trivia'))
WHERE 
    a.name IS NOT NULL
    AND mt.level <= 2
    AND c.nr_order IS NOT NULL
GROUP BY
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    mt.production_year DESC, a.name;
