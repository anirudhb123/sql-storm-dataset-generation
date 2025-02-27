WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL

    UNION ALL
    
    SELECT 
        mk.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        movie_hierarchy mh ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title m ON mk.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    COALESCE(mh.level, 0) AS hierarchy_level,
    COUNT(DISTINCT ci.id) AS role_count,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length -- Assuming info_type_id = 1 is some type of pertinent info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword kt ON kt.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = m.id
WHERE 
    ak.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ak.name, m.title, mh.level
ORDER BY 
    actor_name, movie_title, hierarchy_level;

This SQL query performs the following:

1. **Recursive CTE**: Defines a `movie_hierarchy` that allows you to see how movies are linked in a hierarchy through the `movie_link` table.
2. **Joins**: Uses INNER JOINs to connect the tables based on the relationships defined, and LEFT JOINs to include information on any keywords or additional movie info, even if missing.
3. **COALESCE**: Used to ensure hierarchy levels count is defaulted to zero if no links are found.
4. **Aggregate Functions**: Employs COUNT, AVG, and STRING_AGG to gather actor roles, compute the average length of certain info entries, and compile keywords.
5. **GROUP BY**: Groups results to ensure distinct counts and aggregated data reflect the correct associations.
6. **ORDER BY**: Sorts the results by actor name, movie title, and hierarchy level to structure the output clearly.
