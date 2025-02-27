WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.id] AS hierarchy
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        mh.level + 1,
        mh.hierarchy || ml.linked_movie_id
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS a ON ml.linked_movie_id = a.id
)

SELECT 
    ah.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(dh.neighbor_count, 0) AS neighbor_count,
    mh.level AS link_level,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    STRING_AGG(DISTINCT COALESCE(k.keyword, 'No Keyword'), ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT kw.keyword) > 5 THEN 'UNUSUALLY RICH'
        WHEN COUNT(DISTINCT kw.keyword) BETWEEN 1 AND 5 THEN 'MODERATELY RICH'
        ELSE 'UNDERPLAYED' 
    END AS keyword_richness,
    (SELECT COUNT(*) FROM movie_info mi 
     WHERE mi.movie_id = mt.id 
       AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%review%')
    ) AS review_count
FROM 
    aka_name AS ah
JOIN 
    cast_info AS ci ON ah.person_id = ci.person_id
JOIN 
    aka_title AS mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT linked_movie_id) AS neighbor_count 
     FROM 
         movie_link 
     GROUP BY 
         movie_id) AS dh ON dh.movie_id = mt.id
JOIN 
    MovieHierarchy AS mh ON mh.movie_id = mt.id
WHERE 
    mt.production_year >= 2000
    AND (mt.note IS NULL OR mt.note NOT LIKE '%deleted%')
    AND ah.name IS NOT NULL
GROUP BY 
    ah.name, mt.title, mh.level, dh.neighbor_count
HAVING 
    COUNT(DISTINCT kw.keyword) >= 1
ORDER BY 
    neighbor_count DESC, movie_title, actor_name
LIMIT 50;
