WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mch.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mh.movie_title) AS movie_titles,
    AVG(m.profit) AS avg_profit,
    SUM(m.box_office) AS total_box_office,
    MAX(m.production_year) AS latest_year,
    MIN(m.production_year) AS earliest_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    (
        SELECT 
            mi.movie_id,
            SUM(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info='BoxOffice') THEN CAST(mi.info AS numeric) ELSE 0 END) AS box_office,
            SUM(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info='Profit') THEN CAST(mi.info AS numeric) ELSE 0 END) AS profit
        FROM 
            movie_info mi
        JOIN 
            info_type mt ON mi.info_type_id = mt.id
        GROUP BY 
            mi.movie_id
    ) m ON mh.movie_id = m.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC;
