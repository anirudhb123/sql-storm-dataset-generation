WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title AS movie_title,
        mh.movie_id AS parent_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.depth,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
    AVG(COALESCE(mo.info_text_length, 0)) AS avg_info_text_length
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.person_id = an.person_id 
LEFT JOIN (
    SELECT 
        movie_id,
        LENGTH(info) AS info_text_length
    FROM 
        movie_info
    WHERE 
        info IS NOT NULL AND info <> ''
) mo ON mh.movie_id = mo.movie_id
WHERE 
    mh.depth < 3 -- limit depth to avoid over-fetching
GROUP BY 
    mh.movie_id, mh.movie_title, mh.depth
HAVING 
    COUNT(DISTINCT cc.person_id) > 0 AND 
    AVG(COALESCE(mo.info_text_length, 0)) > 100 -- ensuring relevance
ORDER BY 
    mh.depth, total_cast DESC;

### Explanation:
1. **CTE with Recursion**: The `movie_hierarchy` CTE uses recursion to build a hierarchy of movies from a seed set starting with movies produced after 2000. The hierarchy shows links between movies, considering a potential infinite number of links.

2. **Main Select**: The main query selects from the `movie_hierarchy` CTE, counting distinct cast members for each movie and aggregating their names into a string of comma-separated values.

3. **Left Joins**: 
   - The `complete_cast` table is left-joined to gather cast members.
   - The `aka_name` table is left-joined to gather names for the cast members.
   - A subquery calculates the length of information in `movie_info`, left-joined to get various text lengths.

4. **Complex WHERE Logic**: The query includes predicates to filter on hierarchy depth and ensures that there are cast members while enforcing minimum average character lengths of related info texts.

5. **GROUP BY and HAVING**: The query groups by each movie and checks the count of distinct cast members and average text length to ensure only movies with significant data are returned.

6. **Ordering**: The results are ordered first by depth and then by the total number of cast members, offering an organized and structured output.

By utilizing various SQL constructs, this query adheres to performance benchmarking complexities.
