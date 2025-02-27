WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CHAR_LENGTH(mt.title)) AS avg_title_length,
    SUM(CASE WHEN mt.production_year < 2010 THEN 1 ELSE 0 END) AS pre_2010_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(COALESCE(m.producer, 'Unknown Producer')) AS producer_name
FROM 
    movie_hierarchy mh
JOIN 
    cast_info c ON mh.movie_id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Producer')
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
         mc.movie_id, 
         GROUP_CONCAT(cn.name SEPARATOR ', ') AS producer
    FROM 
         movie_companies mc
    JOIN 
         company_name cn ON mc.company_id = cn.id
    WHERE 
         mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Producer')
    GROUP BY 
         mc.movie_id) m ON mt.id = m.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title
HAVING 
    COUNT(DISTINCT c.person_id) > 1
ORDER BY 
    avg_title_length DESC, 
    actor_name;
