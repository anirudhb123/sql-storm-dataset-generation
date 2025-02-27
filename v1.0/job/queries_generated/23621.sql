WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA' AND t.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3 -- limiting depth to avoid excessive recursion
)
SELECT 
    mh.title AS child_movie,
    pm.title AS parent_movie,
    COUNT(ci.role_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    MAX(mn.info) FILTER (WHERE it.info LIKE '%Award%') AS award_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
LEFT JOIN 
    title pm ON ml.linked_movie_id = pm.id
LEFT JOIN 
    movie_info mn ON mh.movie_id = mn.movie_id 
LEFT JOIN 
    info_type it ON mn.info_type_id = it.id
GROUP BY 
    mh.movie_id, pm.title
HAVING 
    COUNT(ci.role_id) > 0
ORDER BY 
    COUNT(ci.role_id) DESC, mh.level, mh.title;

This query achieves the following:

1. It creates a recursive Common Table Expression (CTE) `movie_hierarchy` to build a hierarchy of movies, linking them based on the movie links, with a depth limit to avoid excessive recursion.
2. It fetches child movies along with their corresponding parent movies.
3. It counts the total number of cast members for each movie, collecting their names into a comma-separated string.
4. A filtered aggregation is included to find if there's any related award information for each movie.
5. The results are grouped, ensuring that only movies with cast members are presented, and the output is sorted by the number of cast members and by levels in the hierarchy.
