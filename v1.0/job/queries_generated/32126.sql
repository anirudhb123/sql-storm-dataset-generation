WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    h.title AS root_movie_title,
    h.production_year AS root_movie_year,
    COUNT(*) AS related_movie_count,
    AVG(CASE WHEN h.kind_id = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY h.production_year) AS avg_drama_related_movies,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    STRING_AGG(DISTINCT c.name, ', ') AS companies,
    MAX(COALESCE(pi.info, 'No info')) AS person_info
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = 1
WHERE 
    h.level <= 2  -- limit to direct and one level of connection
GROUP BY 
    h.movie_id, h.title, h.production_year
ORDER BY 
    related_movie_count DESC, root_movie_year DESC;

This query does the following:
- It constructs a recursive CTE (`MovieHierarchy`) to navigate through a tree of related movies by joining on the `movie_link` table.
- It selects movies within 2 levels of linkage and calculates various aggregates, such as counting related movies, and calculating the average number of drama-related movies.
- It uses `STRING_AGG` to concatenate names of actors and companies associated with the movies.
- The `COALESCE` function provides a fallback string when no person info is available.
- The final output groups results by each movie while ordering them by the number of related movies and production year, making it useful for performance benchmarking in retrieving related movie data.
