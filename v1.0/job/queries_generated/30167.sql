WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id
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
        ml.linked_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(ki.keyword, 'No Keyword') AS main_keyword,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE NULL END) AS average_note_presence
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year IS NOT NULL AND mh.production_year < 2023
GROUP BY 
    mh.title, mh.production_year, ki.keyword
ORDER BY 
    mh.production_year DESC, actor_count DESC
LIMIT 10;
