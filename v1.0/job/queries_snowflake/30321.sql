
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level 
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ca.movie_id) AS total_movies,
    LISTAGG(DISTINCT mk.title, ', ') WITHIN GROUP (ORDER BY mk.title) AS movies_list,
    MAX(mh.production_year) AS latest_movie_year,
    COUNT(DISTINCT mh.movie_id) AS movies_in_hierarchy,
    SUM(CASE WHEN mh.production_year IS NULL THEN 1 ELSE 0 END) AS null_year_count
FROM 
    aka_name ak
JOIN 
    cast_info ca ON ak.person_id = ca.person_id
LEFT JOIN 
    MovieHierarchy mh ON ca.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mk ON ca.movie_id = mk.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND ak.id IN (
        SELECT 
            DISTINCT c.person_id 
        FROM 
            cast_info c 
        JOIN 
            role_type r ON c.role_id = r.id 
        WHERE 
            r.role LIKE '%lead%'
    )
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ca.movie_id) > 5
ORDER BY 
    total_movies DESC;
