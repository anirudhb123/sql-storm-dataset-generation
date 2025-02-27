WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        CONCAT(m.title, ' (Linked)') AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 -- Limit depth to 3 levels for demonstration
), 
ActorRoleDetails AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT c.movie_id) AS num_movies
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, ak.name, r.role
), 
FilteredMovieInfo AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.movie_title) AS rn
    FROM 
        MovieHierarchy m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
)
SELECT 
    f.movie_title,
    f.production_year,
    ad.actor_name,
    ar.num_movies,
    COUNT(DISTINCT m.movie_id) AS total_movies_linked,
    CASE 
        WHEN ar.num_movies IS NULL THEN 'No Role'
        ELSE ar.role_name
    END AS role_description
FROM 
    FilteredMovieInfo f
LEFT JOIN 
    movie_link ml ON f.movie_id = ml.movie_id
LEFT JOIN 
    aka_title m ON ml.linked_movie_id = m.id
LEFT JOIN 
    ActorRoleDetails ar ON ar.actor_id = m.id
LEFT JOIN 
    aka_name an ON ar.actor_id = an.person_id
GROUP BY 
    f.movie_title, f.production_year, an.actor_name, ar.num_movies, ar.role_name
HAVING 
    COUNT(DISTINCT m.movie_id) > 1 OR ar.num_movies IS NOT NULL
ORDER BY 
    f.production_year DESC, f.movie_title;

This query does the following:
1. It uses a recursive CTE to build a hierarchy of movies linked with other movies, limiting the depth to 3 levels and filtering for movies produced from 2000 onwards.
2. It collects actor details, including their roles and counts of movies.
3. It combines these data sources, allowing for the discovery of linked movies and roles through various relationships.
4. Finally, it produces a result set which displays a list of unique movies and their linked counterparts with actors along with several calculations and strings, applying appropriate filtering to only show pertinent records.

