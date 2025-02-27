WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    STRING_AGG(DISTINCT CONCAT(m.title, ' (', m.production_year, ')'), ', ') AS movies_list,
    MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 'Unknown' END) AS last_movie_year,
    SUM(CASE WHEN w.kind IS NOT NULL THEN 1 ELSE 0 END) AS has_roles_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    comp_cast_type w ON w.id = c.person_role_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) >= 1
ORDER BY 
    movies_count DESC
LIMIT 20;

-- Additional metrics for performance benchmarking
SELECT 
    COUNT(*) AS total_records,
    AVG(movies_count) AS avg_movies_per_actor,
    COUNT(DISTINCT a.person_id) AS distinct_actors
FROM (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
) AS actor_movies;
