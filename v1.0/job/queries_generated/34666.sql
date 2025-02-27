WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        title.title,
        title.production_year,
        1 AS level
    FROM 
        aka_title AS title
    JOIN 
        movie_link AS ml ON title.id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END) AS num_directors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name ASC) AS role_order
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS m ON ci.movie_id = m.id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    AND a.name IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    m.production_year DESC, a.name;
