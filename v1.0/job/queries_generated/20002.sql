WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        l.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link l
    JOIN
        MovieHierarchy mh ON l.movie_id = mh.movie_id
    JOIN
        aka_title mt ON l.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    mh.depth AS movie_depth,
    wm.avg_rating AS average_rating,
    COALESCE(mv_info.info, 'No information available') AS additional_info,
    DENSE_RANK() OVER (PARTITION BY ak.person_id ORDER BY COALESCE(wm.avg_rating, 0) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    (SELECT 
        movie_id, 
        AVG(CASE WHEN rating IS NOT NULL THEN rating ELSE 0 END) AS avg_rating
     FROM 
        movie_info mi
     LEFT JOIN 
        (SELECT 
             movie_id, 
             SUM(CASE WHEN note = 'rating' THEN CAST(info AS FLOAT) END) AS rating 
         FROM 
             movie_info 
         GROUP BY 
             movie_id) ratings 
     ON mi.movie_id = ratings.movie_id
     GROUP BY 
        movie_id) wm ON mt.id = wm.movie_id
LEFT JOIN 
    movie_info mv_info ON mv_info.movie_id = mt.id AND mv_info.info_type_id = (SELECT id FROM info_type WHERE info = 'additional')
WHERE 
    ak.name IS NOT NULL 
AND 
    (mt.production_year BETWEEN 2000 AND 2023 OR mh.depth > 1)
ORDER BY 
    actor_rank,
    movie_depth DESC;
