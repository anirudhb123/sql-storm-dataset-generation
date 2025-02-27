WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
PersonRoleInfo AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS role_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        char_name cn ON ci.person_role_id = cn.id
    GROUP BY 
        ci.person_id, ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    COALESCE(pri.role_count, 0) AS total_roles,
    COALESCE(mk.keyword_count, 0) AS total_keywords,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    PersonRoleInfo pri ON mh.movie_id = pri.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level < 5
ORDER BY 
    mh.level, mh.movie_id;

This SQL query performs the following tasks:

1. **Recursive CTE (`MovieHierarchy`)**: Constructs a hierarchy of movies by linking movies to their linked counterparts via `movie_link`. It retrieves all movies of the type 'movie' and iterates through linked movies, establishing levels to limit the hierarchy depth.

2. **CTE (`PersonRoleInfo`)**: Aggregates roles per person in each movie where it counts the number of roles that aren't null and combines role names into a single string.

3. **CTE (`MovieKeywords`)**: Counts the distinct keywords associated with each movie, providing insight into its thematic tagging.

4. **Final Select Statement**: Combines all CTEs via left joins to provide a comprehensive view of each movie's hierarchy, associated roles, and keywords. It filters for hierarchy levels under 5 and orders the results for readability.

This complex query utilizes elements like CTEs, joins, aggregation functions, and string aggregation to benchmark performance on potentially large relational data sets.
