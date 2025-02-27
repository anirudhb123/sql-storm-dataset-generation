WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year IS NOT NULL
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT an.name, ', ') FILTER (WHERE an.name IS NOT NULL) AS actor_names,
    AVG(CASE 
        WHEN YEAR(mh.production_year) < 2010 THEN 5 
        ELSE (SELECT AVG(COALESCE(mi.info::int, 0)) 
              FROM movie_info mi 
              WHERE mi.movie_id = mh.movie_id 
              AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating'))
    END) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 
    AND mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, total_cast DESC;
