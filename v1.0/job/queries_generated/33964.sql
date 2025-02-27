WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    mh.level = 1 -- Only consider top-level movies
    AND mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, cast_count DESC;

This SQL query performs the following actions:
1. It defines a recursive Common Table Expression (CTE) called `MovieHierarchy` that establishes a hierarchy of movies based on linked movies, filtering by the kind of movie from `kind_type`.
2. It selects relevant columns from the `MovieHierarchy`, in addition to the count of distinct cast members and concatenated names of actors.
3. The query filters to only include top-level movies (level = 1) that were produced from the year 2000 onwards.
4. It groups the results by movie information, ensuring that movies with no cast are excluded.
5. Finally, it orders the result set by production year (most recent first) and by the number of cast members.
