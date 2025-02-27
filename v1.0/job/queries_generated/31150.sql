WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(ci.note, 'No role specified') AS role_note,
    COUNT(DISTINCT mh.linked_movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT mt2.title, ', ') FILTER (WHERE mt2.title IS NOT NULL) AS linked_movie_titles
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_hierarchy mh ON mt.id = mh.movie_id
LEFT JOIN movie_link ml ON mt.id = ml.movie_id
LEFT JOIN title mt2 ON ml.linked_movie_id = mt2.id AND mt2.production_year >= 2000
WHERE mt.kind_id IS NOT NULL
GROUP BY ak.name, mt.title, mt.production_year, ci.note
HAVING COUNT(DISTINCT mh.linked_movie_id) > 0
ORDER BY linked_movies_count DESC, movie_title;
