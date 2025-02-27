WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 'movie'
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        m.title,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title linked ON linked.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = linked.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COUNT(DISTINCT c.id) AS total_roles,
    AVG(CASE WHEN t.production_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year ELSE NULL END) AS avg_age_of_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(company.name, 'Unknown') AS company_name,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count
FROM 
    cast_info c
INNER JOIN 
    aka_name a ON a.person_id = c.person_id
INNER JOIN 
    aka_title t ON t.id = c.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name company ON company.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (c.note IS NULL OR c.note <> 'refused')
GROUP BY 
    a.name, t.title, company.name
ORDER BY 
    total_roles DESC, avg_age_of_movies ASC;
