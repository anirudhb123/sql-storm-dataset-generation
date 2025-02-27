WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        ARRAY[mt.title] AS ancestry
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        linked.title,
        mh.level + 1,
        linked.production_year,
        mh.ancestry || linked.title
    FROM 
        movie_link ml
    JOIN 
        title linked ON ml.linked_movie_id = linked.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name AS person_name,
    m.title AS movie_title,
    m.production_year,
    mt.kind AS movie_type,
    ARRAY_AGG(k.keyword) AS keywords,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS total_cast,
    STRING_AGG(DISTINCT n.name, ', ') AS unique_crew_names
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info c ON c.movie_id = m.movie_id
JOIN 
    aka_name p ON p.person_id = c.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
JOIN 
    keyword k ON k.id = mk.keyword_id 
JOIN 
    kind_type mt ON m.kind_id = mt.id
LEFT JOIN 
    name n ON n.id = c.id
WHERE 
    n.gender = 'M'
GROUP BY 
    p.name, m.title, m.production_year, mt.kind
HAVING 
    COUNT(DISTINCT k.id) > 2
    AND SUM(CASE WHEN n.name IS NULL THEN 1 ELSE 0 END) < 3
ORDER BY 
    m.production_year DESC, p.name;
