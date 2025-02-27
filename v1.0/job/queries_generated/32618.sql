WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        m.linked_movie_id,
        1 AS depth
    FROM movie_link m
    JOIN title t ON m.movie_id = t.id
    WHERE t.production_year >= 2000
    
    UNION ALL

    SELECT 
        ml.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS linked_title,
    mh.production_year AS linked_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    COUNT(DISTINCT ci.id) AS cast_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order,
    MAX(CASE WHEN pi.info IS NOT NULL THEN pi.info ELSE 'No info' END) AS personal_info,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.depth DESC) AS row_num
FROM movie_hierarchy mh
LEFT JOIN aka_title ak ON mh.movie_id = ak.movie_id
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY mh.movie_id, mh.title, mh.production_year
HAVING COUNT(DISTINCT ci.id) > 0
ORDER BY mh.production_year DESC, linked_title;
