WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title m
    WHERE 
        m.season_nr IS NULL 
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title AS movie_title,
    mv.production_year,
    ak.name AS actor_name,
    COALESCE(ki.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    ROW_NUMBER() OVER (PARTITION BY mv.id ORDER BY ak.name) AS actor_rank,
    AVG(COALESCE(person.rating, 0)) AS avg_rating
FROM 
    movie_hierarchy mv
LEFT JOIN 
    cast_info ci ON mv.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_link ml ON mv.movie_id = ml.movie_id
LEFT JOIN 
    (SELECT 
        movie_id,
        AVG(CASE 
                WHEN rating IS NULL THEN 0 
                ELSE rating 
            END) AS rating
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
         movie_id) AS person ON mv.movie_id = person.movie_id
GROUP BY 
    mv.title, mv.production_year, ak.name, ki.keyword
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY 
    mv.production_year DESC, actor_rank;
