WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth 
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL 
    UNION ALL
    SELECT 
        mc.linked_movie_id,
        mt.title,
        mt.production_year,
        depth + 1
    FROM 
        movie_link AS mc
    INNER JOIN 
        aka_title AS mt ON mc.movie_id = mt.id
    INNER JOIN 
        movie_hierarchy AS mh ON mh.movie_id = mc.movie_id
    WHERE 
        depth < 5 
)
SELECT 
    ak.id AS person_id,
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.id) AS total_roles,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_with_notes,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ci.role_id) > 3 THEN 'Versatile Actor'
        ELSE 'Specialized Actor'
    END AS actor_type,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    aka_name AS ak
LEFT JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
    AND mh.production_year >= 2000
    AND mh.production_year <= (SELECT EXTRACT(YEAR FROM NOW()))
GROUP BY 
    ak.id, ak.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 0
ORDER BY 
    total_roles DESC, avg_roles_with_notes DESC;
