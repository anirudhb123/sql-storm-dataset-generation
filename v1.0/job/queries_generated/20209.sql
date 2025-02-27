WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS depth 
    FROM 
        aka_title mt 
    WHERE 
        mt.id IN (SELECT linked_movie_id FROM movie_link)

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.depth + 1 
    FROM 
        MovieHierarchy mh 
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id 
        JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name, 
    ARRAY_AGG(DISTINCT mk.keyword) AS associated_keywords,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(COALESCE(ki.info::INTEGER, 0)) AS avg_info_id,
    COUNT(DISTINCT mh.movie_id) FILTER (WHERE mh.depth = 1) AS directly_linked_movies,
    MAX(mh.depth) AS max_depth,
    STRING_AGG(DISTINCT CASE 
        WHEN ak.surname_pcode IS NULL THEN 'N/A' 
        ELSE ak.surname_pcode END, ', ') AS surname_codes
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    (SELECT 
        mt.movie_id, 
        mi.info 
     FROM 
        movie_info mi 
     JOIN 
        kind_type kt ON mi.info_type_id = kt.id 
     WHERE 
        kt.kind LIKE '%rating%'
    ) ki ON at.id = ki.movie_id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.id IS NOT NULL 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name 
ORDER BY 
    avg_info_id DESC NULLS LAST
LIMIT 50;

### Explanation of the SQL Query:
- **CTE (Common Table Expression)**: The `MovieHierarchy` CTE is defined recursively to create a hierarchy of movies based on their links to other movies, allowing exploration of direct and indirect relationships.
  
- **Main SELECT Statement**:
  - **Selecting Names**: It fetches names from `aka_name` and associates them with various metrics.
  - **Associating Keywords**: It aggregates keywords linked to the movies where the person acted.
  - **Counting Movies**: It counts how many movies are associated with each person's account.
  - **Average Info ID**: It computes the average value of an info attribute (like ratings) for each movie.
  - **Filtered Count of Linked Movies**: This counts how many movies are linked directly (depth = 1).
  - **Maximum Depth**: It calculates the maximum depth (degree of link) for each movie related to the actor.
  - **String Aggregation with NULL Logic**: It concatenates the surname codes and manages NULLs gracefully by delivering a default value of 'N/A'.
  
- **Left Joins**: The query extensively uses `LEFT JOIN` to ensure all actor names from `aka_name` are included, regardless of whether they have corresponding data in other tables. 

- **WHERE Clause**: Includes conditions to ensure no NULL actors or names are considered.

- **ORDER BY and LIMIT**: Finally, it orders the results by the average info ID in a descending manner (with NULLs last) and limits the output to 50 entries.

This query uses a variety of SQL constructs, including aggregation, filtering, conditional logic, recursive queries, and string manipulation to test database performance on complex operations.
