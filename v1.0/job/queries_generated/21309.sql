WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        DISTINCT ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3 
        AND at.production_year IS NOT NULL
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(nc.gender, 'Unknown') AS actor_gender,
    COUNT(DISTINCT cc.subject_id) AS total_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS total_notes,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.subject_id) DESC) AS rank_by_cast
FROM 
    movie_companies AS mc
JOIN 
    aka_title AS mt ON mc.movie_id = mt.id
LEFT JOIN 
    complete_cast AS cc ON mt.id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN 
    name AS n ON ak.id = n.id 
LEFT JOIN 
    char_name AS nc ON ak.id = nc.imdb_id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
    AND (mc.company_id IS NULL OR mc.note IS NOT NULL)
GROUP BY 
    ak.name, mt.title, mt.production_year, nc.gender
HAVING 
    COUNT(DISTINCT cc.subject_id) > 1 
    OR total_notes > 0
ORDER BY 
    rank_by_cast, actor_name, movie_title;
