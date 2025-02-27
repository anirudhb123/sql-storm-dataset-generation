WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(p.name, 'Unknown') AS director,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id AND c.role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(d.name, 'Unknown') AS director,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title d ON ml.linked_movie_id = d.id
)
SELECT 
    mh.title,
    mh.director,
    mh.level,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mi.info IS NOT NULL::int) AS presence_ratio
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')
GROUP BY 
    mh.title, mh.director, mh.level
HAVING 
    COUNT(DISTINCT kc.keyword) > 2 OR mh.level > 1
ORDER BY 
    mh.level, keyword_count DESC, mh.title ASC;

**Explanation of the SQL Query:**
- The query starts with a Common Table Expression (CTE) called `movie_hierarchy`, which builds a recursive relationship between movies and their links (like sequels or franchises) using a self-referential manner via the `movie_link` table.
- Various joins are performed: 
    - A left join with `cast_info` to retrieve directors. 
    - A left join with `aka_name` to get the director's name, using COALESCE to handle NULLs gracefully.
- The main SELECT statement aggregates data from this hierarchy.
- It counts distinct keywords related to the movie and calculates the ratio of the presence of summaries.
- The GROUP BY encompasses movie titles, directors, and their levels in the hierarchy.
- The HAVING clause filters for movies with more than 2 distinct keywords or levels greater than 1.
- The results are ordered by the hierarchical level first, then by the keyword count in descending order, and finally in ascending order of titles. 

This query leverages recursion, aggregates and filters data based on complex relationships, handles NULL values effectively, and demonstrates advanced SQL capabilities such as window-like functions through aggregation instead of traditional window functions.
