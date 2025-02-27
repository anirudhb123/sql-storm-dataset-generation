WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, mt.id) AS linked_movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ml.linked_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(gender_counts.male_count, 0) AS male_count,
    COALESCE(gender_counts.female_count, 0) AS female_count,
    COUNT(DISTINCT mh.linked_movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT i.info, ', ') AS movie_info
FROM 
    movie_hierarchy mh 
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_info i ON mh.movie_id = i.movie_id
LEFT JOIN (
    SELECT 
        c.movie_id,
        SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.imdb_id
    GROUP BY 
        c.movie_id
) AS gender_counts ON mh.movie_id = gender_counts.movie_id
GROUP BY 
    ak.name, mt.title, mt.production_year, gender_counts.male_count, gender_counts.female_count
HAVING 
    COUNT(DISTINCT mh.linked_movie_id) > 0
ORDER BY 
    movie_title ASC, production_year DESC;
