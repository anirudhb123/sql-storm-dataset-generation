
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    k.keyword,
    COUNT(DISTINCT c.person_id) AS total_cast,
    SUM(CASE WHEN c.person_role_id = 1 THEN 1 ELSE 0 END) AS total_actors,
    SUM(CASE WHEN c.person_role_id = 2 THEN 1 ELSE 0 END) AS total_directors,
    LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actor_names,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS year_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_name an ON c.person_id = an.person_id
WHERE 
    mh.production_year >= 2000
    AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
GROUP BY 
    mh.movie_title, mh.production_year, k.keyword, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 3
ORDER BY 
    mh.production_year DESC, total_cast DESC;
