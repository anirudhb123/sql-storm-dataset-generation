WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id AS root_movie_id,
        mt.id AS root_id,
        0 AS level,
        mt.title AS root_title
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)
    UNION ALL
    SELECT 
        ml.linked_movie_id AS root_movie_id,
        ml.id AS root_id,
        mh.level + 1,
        at.title
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.root_movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.person_id,
    ak.name,
    COUNT(DISTINCT ca.movie_id) AS total_movies,
    COUNT(DISTINCT CASE WHEN ct.kind = 'Actor' THEN ca.movie_id END) AS actor_movies,
    STRING_AGG(DISTINCT CONCAT('Title: ', ak.title, ' | Year: ', ak.production_year)) AS titles,
    MAX(CASE WHEN ak.production_year IS NULL THEN 'Unknown Year' ELSE ak.production_year END) AS last_known_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ca.movie_id) DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ca ON ak.person_id = ca.person_id
JOIN 
    aka_title at ON ca.movie_id = at.id
LEFT JOIN 
    comp_cast_type ct ON ca.person_role_id = ct.id
LEFT JOIN 
    MovieHierarchy mh ON mh.root_movie_id = ca.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> '' 
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = ca.movie_id 
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Filming Location')
          AND mi.info IS NULL
    )
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT ca.movie_id) > 1
ORDER BY 
    rank
LIMIT 50;

