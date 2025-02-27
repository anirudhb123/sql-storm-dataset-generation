WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mo.title AS movie_title,
    mo.production_year,
    COUNT(c.id) AS total_cast,
    AVG(r.role_id) AS average_role_id,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.status_id IS NULL THEN 1 ELSE 0 END) AS null_status_count 
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_hierarchy mo ON c.movie_id = mo.movie_id
LEFT JOIN 
    movie_keyword mk ON mo.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = c.movie_id AND cc.subject_id = c.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    mo.production_year >= 2000 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, mo.title, mo.production_year
HAVING 
    COUNT(c.id) > 1 
ORDER BY 
    mo.production_year DESC, a.name;
