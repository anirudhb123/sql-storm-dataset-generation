WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(mti.info, 'No Information') AS movie_info,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mti ON mt.id = mti.movie_id AND mti.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Plot'
        )
    WHERE 
        mt.production_year < 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        COALESCE(mti.info, 'No Information') AS movie_info,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        movie_info mti ON mt.id = mti.movie_id AND mti.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Synopsis'
        )
)

SELECT 
    mh.movie_title,
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS co_actors,
    SUM(CASE WHEN mt.production_year >= 1990 THEN 1 ELSE 0 END) AS count_of_modern_movies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
GROUP BY 
    mh.movie_title, mh.depth
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND 
    MAX(mh.depth) < 5
ORDER BY 
    mh.depth DESC, 
    actor_count DESC
LIMIT 50;
