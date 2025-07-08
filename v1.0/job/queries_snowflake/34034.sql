
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(cast_info.nr_order, 0) AS order_no,
        0 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ON m.id = cast_info.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(ci.nr_order, 0) AS order_no,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    LEFT JOIN 
        cast_info ci ON mv.id = ci.movie_id
)

SELECT 
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    LISTAGG(DISTINCT mh.title, ', ') WITHIN GROUP (ORDER BY mh.title) AS movie_titles,
    SUM(CASE WHEN mh.production_year = 2021 THEN 1 ELSE 0 END) AS movies_in_2021,
    AVG(mh.order_no) AS avg_order_no,
    RANK() OVER (ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    mh.level = 0
GROUP BY 
    ak.name, mh.order_no
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    movie_rank
LIMIT 10;
