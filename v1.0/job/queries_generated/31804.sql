WITH RECURSIVE MovieHierarchy AS (
    -- CTE to find all movies and their immediate sequels.
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (1, 2)  -- Assuming 1: Movie, 2: Series

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
-- Select movies from the hierarchy
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(mk.keywords, 'None') AS related_keywords,
    COALESCE(pi.info, 'No Info') AS director_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id AND ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title ASC
LIMIT 50;

-- Additionally count the movies with no directors
SELECT 
    COUNT(*) AS total_movies_without_directors
FROM 
    aka_title mt
WHERE 
    mt.id NOT IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_role_id IN (SELECT id FROM role_type WHERE role = 'Director'));

This query utilizes a recursive CTE to construct a hierarchy of movies and their sequels, incorporates multiple outer joins to gather additional details on keywords and director information, applies a filter on production year, and demonstrates aggregate functions to count movies without directors, showcasing a variety of SQL constructs and logic.
