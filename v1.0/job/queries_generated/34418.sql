WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.depth,
    COUNT(c.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE WHEN ci.note ILIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    MAX(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) as max_order
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    m.depth < 3
GROUP BY 
    m.movie_id, m.title, m.production_year, m.depth
HAVING 
    COUNT(c.person_id) > 0
ORDER BY 
    m.production_year DESC, m.title;

This SQL query performs the following operations:

1. It defines a recursive Common Table Expression (`movie_hierarchy`) to find movies and their linked counterparts produced after the year 2000, while also generating a depth for hierarchical movie links.
2. It selects movie details from the `movie_hierarchy`, joining with the `complete_cast`, `cast_info`, and `aka_name` tables to gather information about cast members.
3. It calculates the number of cast members per movie, aggregates actor names, counts lead roles, and finds the maximum order of cast members (with NULL handling).
4. It filters results to those with at least one cast member and orders the output based on production year and title.
