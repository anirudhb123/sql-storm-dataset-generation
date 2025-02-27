WITH RECURSIVE MoviePath AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mp.depth + 1
    FROM 
        MoviePath mp
    JOIN 
        movie_link ml ON ml.movie_id = mp.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    WHERE 
        mp.depth < 3
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT cp.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mp.movie_title) AS linked_movies,
    AVG(mp.production_year) AS avg_linked_movie_year,
    SUM(CASE WHEN cp.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    STRING_AGG(DISTINCT p.info, ', ') AS person_info
FROM 
    aka_name ak
INNER JOIN 
    cast_info cp ON ak.person_id = cp.person_id
LEFT JOIN 
    MoviePath mp ON cp.movie_id = mp.movie_id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id
HAVING 
    COUNT(DISTINCT cp.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name
LIMIT 10;
