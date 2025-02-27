WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS TEXT) AS path
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS TEXT) AS path
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit to 5 levels of linked movies
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types,
    AVG(mv_rating.avg_rating) AS average_rating,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS mt ON ci.movie_id = mt.id
JOIN 
    movie_companies AS mc ON mt.id = mc.movie_id
JOIN 
    company_type AS ckt ON mc.company_type_id = ckt.id
LEFT JOIN 
    (SELECT 
         mi.movie_id, 
         AVG(CASE 
             WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS NUMERIC)
             ELSE NULL END) AS avg_rating
     FROM 
         movie_info AS mi
     GROUP BY 
         mi.movie_id) AS mv_rating ON mt.id = mv_rating.movie_id
LEFT JOIN 
    MovieHierarchy AS mh ON mt.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
AND 
    mt.production_year IS NOT NULL
AND 
    (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY 
    a.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    average_rating DESC, 
    mt.production_year DESC;
