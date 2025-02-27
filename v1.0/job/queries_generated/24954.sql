WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        COALESCE(aka.name, 'Unknown') AS movie_name,
        1 AS level
    FROM 
        aka_title AS mt
    LEFT JOIN
        aka_name AS aka ON mt.id = aka.id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.movie_id, 
        m.title,
        m.production_year,
        CONCAT(mh.movie_name, ' (Sequel)') AS movie_name,
        mh.level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)

SELECT 
    mh.movie_name,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_list,
    SUM(
        CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
             THEN CAST(mt.info AS NUMERIC)
             ELSE 0
        END
    ) AS total_budget,
    AVG(
        CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
             THEN CAST(mt.info AS NUMERIC)
             WHEN mt.info_type_id IS NULL 
             THEN NULL
             ELSE 0
        END
    ) AS average_rating
FROM 
    movie_hierarchy AS mh
JOIN 
    movie_companies AS mc ON mh.movie_id = mc.movie_id
JOIN 
    cast_info AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_info AS mt ON mh.movie_id = mt.movie_id
LEFT JOIN 
    aka_name AS ak ON cc.person_id = ak.person_id
GROUP BY 
    mh.movie_name, mh.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 0
ORDER BY 
    average_rating DESC NULLS LAST, total_budget ASC;
