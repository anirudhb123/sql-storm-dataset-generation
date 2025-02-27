WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT ac.person_id) AS actor_count,
    AVG(CASE WHEN ca.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_actor_roles,
    ARRAY_AGG(DISTINCT CONCAT(an.name, ' (', an.surname_pcode, ')')) AS actor_names,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS note_count
FROM 
    movie_keyword AS mk
LEFT JOIN 
    aka_title AS at ON mk.movie_id = at.id
JOIN 
    complete_cast AS cc ON at.id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id AND ci.movie_id = at.id
LEFT JOIN 
    aka_name AS an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_info AS mi ON mi.movie_id = at.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    movie_companies AS mc ON at.id = mc.movie_id
WHERE 
    mk.keyword ILIKE '%comedy%'
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT ac.person_id) > 5
ORDER BY 
    actor_count DESC, avg_actor_roles DESC;
