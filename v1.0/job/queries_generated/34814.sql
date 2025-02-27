WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id AS movie_id, 
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(cast.id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS biography,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cast.id) DESC) AS rank_within_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info cast ON mh.movie_id = cast.movie_id
LEFT JOIN 
    aka_name a ON cast.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    person_info pi ON cast.person_id = pi.person_id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(cast.id) > 2
ORDER BY 
    mh.production_year DESC, cast_count DESC;

This SQL query does the following:

1. **Recursive CTE (`MovieHierarchy`)**: Builds a hierarchy of movies starting with those produced from the year 2000 onwards and linking to any related films via the `movie_link` table.
2. **Main Query**: 
   - Joins `MovieHierarchy` with the `cast_info`, `aka_name`, `movie_keyword`, and `person_info` tables to gather relevant details about the movies, cast, and their keywords and biographies.
   - Computes the number of cast members, a string of distinct cast names, and the count of keywords associated with the movies.
   - Uses `ROW_NUMBER()` window function to rank the movies within each production year by the cast count.
3. **Filters**: 
   - Limits results to a maximum depth of 3 in the movie hierarchy.
   - Ensures that only movies with more than 2 cast members are included.
4. **Ordering**: Results are ordered by production year (most recent first) and by the cast count (most cast members first).
