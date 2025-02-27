WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    kt.keyword AS movie_keyword,
    mt.title AS movie_title,
    mh.production_year,
    mh.hierarchy_level,
    COUNT(DISTINCT c.id) OVER (PARTITION BY mh.movie_id) AS cast_count,
    COALESCE(mt2.note, 'No additional info') AS additional_info_note
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    movie_info_idx mt2 ON mt.id = mt2.movie_id AND mt2.info_type_id = (SELECT id FROM info_type WHERE info = 'Note')
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature film' OR kind = 'documentary')
    AND ak.name IS NOT NULL
    AND (mt.production_year > 2010 OR ak.name LIKE '%Smith%')
ORDER BY 
    mh.hierarchy_level DESC,
    CAST(mh.production_year AS TEXT) || ak.name DESC
LIMIT 
    100 OFFSET 0;
