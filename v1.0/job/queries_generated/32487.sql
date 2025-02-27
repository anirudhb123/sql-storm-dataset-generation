WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.title IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    MAX(CASE 
        WHEN p.gender = 'M' THEN 'Male' 
        WHEN p.gender = 'F' THEN 'Female' 
        ELSE 'Unknown' 
    END) AS gender,
    COALESCE(MAX(ci.note), 'No Role Specified') AS role_info
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000 -- Only consider movies from 2000 onwards
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;

### Explanation:

- **CTE (movie_hierarchy)**: A recursive common table expression is used to build a hierarchy of linked movies.
- **SELECT Statement**: The main query extracts actor names, counts the total movies they've been in, calculates the average depth of linked movies, and aggregates movie titles in a single string.
- **Conditional CASE Statement**: To determine the actor's gender based on the value in the database.
- **COALESCE**: To ensure we return a default value when a role is not specified in the cast_info.
- **JOINs**: Multiple joins are utilized to combine data from various tables (cast_info, aka_name, movie_hierarchy).
- **HAVING Clause**: To filter results, only actors who appeared in more than 5 movies are shown.
- **LIMIT**: To restrict the output to the top 10 actors based on the total number of movies they performed in.
