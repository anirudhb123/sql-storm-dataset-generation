WITH RECURSIVE MovieHierarchy AS (
    -- Base case: retrieve all movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- filter for movies after 2000
    
    UNION ALL
    
    -- Recursive case: join on linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

-- Main query: Collect movie details with cast and production companies
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_present,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 -- ensure only movies with cast are returned
ORDER BY 
    mh.production_year DESC, 
    COUNT(DISTINCT ci.person_id) DESC; -- order by year and cast count

This SQL query does the following:

1. **Recursive CTE (Common Table Expression)**: `MovieHierarchy` generates a hierarchy of movies starting from those produced after the year 2000. It includes linked movies to establish a relationship between them.

2. **Main Query**: It selects relevant movie details, including the title, production year, cast count, a concatenated list of production companies, average presence of roles, and the count of associated keywords.

3. **LEFT JOINs**: Various LEFT JOINs are used to ensure that even if there are movies without cast or companies, they are still included in the result.

4. **Aggregations**: Uses `COUNT`, `AVG`, and `STRING_AGG` to provide summarized information about each movie.

5. **Filtering with HAVING**: Ensures that only movies with at least one cast member are included.

6. **Ordering**: Results are ordered by production year (most recent first) and then by the number of cast members.
