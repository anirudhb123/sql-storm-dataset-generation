WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 corresponds to feature films

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    COALESCE(ak.name, 'Unknown') AS actor_name,
    m.title AS movie_title,
    COUNT(*) FILTER (WHERE ci.role_id IS NOT NULL) AS num_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mi.info_length) AS avg_info_length,
    mh.level AS movie_level
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    ak.name, m.title, mh.level
ORDER BY 
    movie_level DESC, num_roles DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:

- **Common Table Expression (CTE)**: The query starts with a recursive CTE named `movie_hierarchy` that builds a hierarchy of movies based on their linked relationships, allowing for analysis of sequels or related movies. It selects movies only of the kind 'feature film' based on presumed `kind_id` values.

- **Coalescing Names**: The `COALESCE` function is used to replace NULL actor names with 'Unknown'.

- **Aggregate Functions**: The query counts the number of roles associated with each actor in the movie, and aggregates keywords into a single string for each movie using `STRING_AGG`.

- **Average Calculation**: `AVG(mi.info_length)` calculates the average length of information associated with movies, which could be useful for insights into movie data density.

- **Filtering with Aggregate**: The use of the `FILTER` clause counts only those roles that are not NULL, enhancing the accuracy of the role counts.

- **Ordering and Limiting**: Finally, the results are ordered by movie level and then by the number of roles, limiting the output to only the top 10 results.

This query structure showcases multiple SQL constructs while effectively deriving insights from the database schema presented.
