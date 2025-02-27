WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        CAST(0 AS INTEGER) AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id 
    WHERE c.movie_id = (SELECT id FROM title WHERE title LIKE '%Inception%') -- selecting a specific movie for the benchmark

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN actor_hierarchy ah ON c.movie_id = ah.person_id -- Recursive join to get the related actors
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    MAX(t.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    COALESCE(SUM(CASE WHEN mci.company_id IS NULL THEN 1 ELSE 0 END), 0) AS unproduced_movies
FROM actor_hierarchy a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_companies mci ON mci.movie_id = t.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')  -- only get movies with Budget info
WHERE t.production_year >= 2000  -- filtering for movies made after 2000
GROUP BY a.actor_name
HAVING COUNT(DISTINCT m.id) > 5 -- limiting to actors with over 5 movies
ORDER BY last_movie_year DESC;

SELECT 
    COUNT(DISTINCT ci.person_id) AS total_actors,
    SUM(CASE WHEN c.kind = 'Leading' THEN 1 ELSE 0 END) AS leading_roles,
    SUM(CASE WHEN c.kind = 'Supporting' THEN 1 ELSE 0 END) AS supporting_roles
FROM comp_cast_type c 
JOIN cast_info ci ON ci.person_role_id = c.id
JOIN title t ON ci.movie_id = t.id
WHERE t.production_year BETWEEN 2000 AND 2020
GROUP BY c.kind;
