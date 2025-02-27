WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
      
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS FLOAT)
        ELSE NULL 
    END) AS avg_budget,
    ROW_NUMBER() OVER(PARTITION BY ah.person_id ORDER BY mh.production_year DESC) AS movie_rank
FROM 
    MovieHierarchy AS mh
JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name AS ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    movie_companies AS mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info AS mi ON mh.movie_id = mi.movie_id
WHERE 
    ah.name IS NOT NULL AND 
    mh.production_year IS NOT NULL AND 
    (mi.info_type_id IS NULL OR EXISTS (
        SELECT 1 
        FROM movie_info AS sub_mi 
        WHERE sub_mi.movie_id = mh.movie_id AND sub_mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    ))
GROUP BY 
    ah.name, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    movie_rank, mh.production_year DESC;
