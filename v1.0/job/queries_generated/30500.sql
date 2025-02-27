WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        CASE 
            WHEN mt.production_year IS NOT NULL THEN mt.production_year 
            ELSE 0 
        END AS production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming kind_id = 1 represents movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        CASE 
            WHEN lt.production_year IS NOT NULL THEN lt.production_year 
            ELSE 0 
        END,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    COALESCE(mh.production_year, 0) AS initial_release_year,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    movie_hierarchy m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    mh.level < 3  -- Limit to direct and 1-level deep movies
GROUP BY 
    m.movie_id, m.movie_title, mh.production_year
ORDER BY 
    total_cast DESC,
    initial_release_year DESC;

This SQL query uses a recursive common table expression (CTE) to create a hierarchy of movies linked to each other through the `movie_link` table. It pulls in relevant details about each movie, including cast names and the total number of cast members associated with each movie. The base case of the CTE fetches the initial set of movies (assuming those with `kind_id = 1` are movies). The query further aggregates the cast names and counts the distinct cast members to return a detailed analysis suitable for performance benchmarking on movie data. The results are ordered by the number of cast members and the most recent production year.
