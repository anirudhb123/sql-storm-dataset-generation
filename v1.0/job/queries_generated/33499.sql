WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title AS mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    movie.movie_title,
    movie.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(ci.person_id) AS num_roles,
    COUNT(DISTINCT ci.movie_id) AS num_movies,
    ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY movie.production_year DESC) AS rank,
    AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
             THEN pi.info::NUMERIC ELSE NULL END) AS average_rating
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy AS movie ON ci.movie_id = movie.movie_id
LEFT JOIN 
    movie_keyword AS mk ON movie.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    movie.production_year >= 2000
    AND (ci.note IS NULL OR ci.note NOT LIKE '%cameo%')
GROUP BY 
    a.name, movie.movie_title, movie.production_year
ORDER BY 
    num_roles DESC, actor_name ASC;
