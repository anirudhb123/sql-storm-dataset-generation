WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    WHERE 
        t.production_year >= 2000  -- focus on movies from the year 2000 and later

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(ma.average_rating, 0) AS average_user_rating,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
FROM 
    title m
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'user rating')
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(CAST(info AS FLOAT)) AS average_rating 
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'user rating')
     GROUP BY 
         movie_id) ma ON m.id = ma.movie_id
WHERE 
    m.id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%'))
    AND m.production_year IS NOT NULL
GROUP BY 
    m.id, m.title, m.production_year, ma.average_rating
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    average_user_rating DESC, total_cast DESC;
