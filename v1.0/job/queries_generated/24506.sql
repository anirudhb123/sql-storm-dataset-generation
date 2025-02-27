WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        sub.title,
        sub.production_year,
        sub.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title sub ON sub.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    ARRAY_AGG(DISTINCT a.name) AS alias_names,
    COALESCE(COUNT(ci.id) FILTER (WHERE ci.note IS NULL), 0) AS total_cast,
    COALESCE(SUM(CASE WHEN ci.nr_order > 5 THEN 1 ELSE 0 END), 0) AS prominent_roles,
    CONCAT('Year: ', mh.production_year, ', Title: ', mh.title) AS description,
    (SELECT AVG(star_rating) FROM movie_info mi WHERE mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS average_rating
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    mh.production_year BETWEEN 1990 AND 2023
    AND COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    average_rating DESC NULLS LAST,
    mh.production_year, 
    mh.level;
