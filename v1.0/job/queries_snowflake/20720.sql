
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_link AS ml ON mt.id = ml.movie_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL 

    UNION ALL

    SELECT 
        h.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        h.depth + 1
    FROM 
        movie_hierarchy AS h
    JOIN 
        movie_link AS ml ON h.linked_movie_id = ml.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    WHERE 
        h.depth < 3 
)

SELECT 
    a.id AS aka_id,
    a.name,
    a.md5sum,
    th.title AS top_level_title,
    mh.depth,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    LISTAGG(DISTINCT th.title, ', ') WITHIN GROUP (ORDER BY th.title) AS linked_titles,
    CASE 
        WHEN COUNT(DISTINCT i.info) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_additional_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy AS mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title AS th ON mh.movie_id = th.id
LEFT JOIN 
    movie_info AS i ON th.id = i.movie_id AND i.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
GROUP BY 
    a.id, a.name, a.md5sum, th.title, mh.depth
HAVING 
    COUNT(DISTINCT c.movie_id) > 1 
    AND (mh.depth IS NULL OR mh.depth = 1 OR mh.depth > 2)
ORDER BY 
    total_movies DESC,
    a.name ASC
LIMIT 50;
