WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.depth + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.depth,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS num_distinct_cast,
    STRING_AGG(DISTINCT an.name, ', ' ORDER BY an.name) AS actors,
    SUM(CASE 
        WHEN ci.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS notes_count,
    AVG(CASE 
        WHEN mt.production_year IS NOT NULL THEN mt.production_year 
        ELSE CAST(NULL AS INTEGER) 
    END) AS avg_production_year,
    COUNT(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS num_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    (mt.kind_id IS NULL OR mt.kind_id NOT IN (SELECT id FROM kind_type WHERE kind ILIKE '%documentary%'))
    AND (mh.depth <= 3 OR mh.path ILIKE '%Comedy%')
GROUP BY 
    mh.depth, mh.path
ORDER BY 
    mh.depth, num_distinct_cast DESC, avg_production_year DESC
LIMIT 100;

This SQL query does the following:
- It defines a recursive Common Table Expression (CTE) called `movie_hierarchy` to create a hierarchy of movies linked together, traversing the links using the `movie_link` table.
- The main SELECT statement retrieves details about the movies and casts from this hierarchy, including depth, path of linked movies, count of distinct cast members, concatenated actor names, and the average production year.
- It filters to exclude documentary films and only considers specific depths in the hierarchy.
- Finally, it groups the results by depth and path and orders them based on the number of distinct cast members and average production year. 

This query is both intricate in logic and covers various SQL constructs like CTEs, joins, aggregates, filters, and string manipulation.
