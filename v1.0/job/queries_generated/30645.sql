WITH RECURSIVE MovieHierachy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierachy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year >= 2000
)

SELECT 
    ak.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mv.movie_id) AS movies_count,
    MAX(mv.production_year) AS last_production_year,
    STRING_AGG(DISTINCT akn.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mv.movie_id) DESC) AS ranking,
    CASE 
        WHEN COUNT(DISTINCT mv.movie_id) = 0 THEN NULL
        ELSE MAX(mv.production_year) - MIN(mv.production_year)
    END AS year_gap,
    SUM(CASE WHEN c.role_id = rt.id THEN 1 ELSE 0 END) AS specific_role_count
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    MovieHierachy mv ON c.movie_id = mv.movie_id
INNER JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    aka_name akn ON ak.person_id = akn.person_id AND akn.id != ak.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mv.movie_id) >= 5
ORDER BY 
    ranking
LIMIT 50;
