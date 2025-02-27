WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mk.production_year >= 2000
)
SELECT 
    a.id AS actor_id,
    an.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    MAX(mh.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS has_ordered_roles,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
FROM 
    cast_info ci
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    an.name IS NOT NULL 
    AND (an.imdb_index IS NULL OR an.imdb_index LIKE 'A%')
GROUP BY 
    a.id, an.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    latest_movie_year DESC
LIMIT 25;

This query generates a comprehensive analysis of actors who have featured in a significant number of movies, particularly linked to other films produced from the year 2000 onward. Features include recursive common table expressions (CTEs) for movie hierarchies, conditional aggregations, string manipulation for listing movie titles, and handling NULL values to filter the results accurately. The output is sorted to showcase the latest productions, enhancing clarity on recent actor engagements.
