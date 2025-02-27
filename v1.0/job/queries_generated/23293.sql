WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(t2.title, 'N/A') AS parent_title,
        0 AS level
    FROM 
        title m
    LEFT JOIN 
        title t2 ON m.episode_of_id = t2.id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        ch.id AS movie_id,
        ch.title,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        title ch
    JOIN 
        MovieHierarchy mh ON ch.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.parent_title,
    mh.level,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY mh.movie_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN CAST(mi.info AS FLOAT)
            ELSE NULL 
       END) AS average_rating,
    COUNT(DISTINCT CASE 
            WHEN mk.id IS NOT NULL THEN mk.keyword_id 
            END) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.level < 3
GROUP BY 
    mh.movie_id, mh.title, mh.parent_title, mh.level
HAVING 
    AVG(COALESCE(CAST(mi.info AS FLOAT), 0)) > 7
ORDER BY 
    mh.level, actor_count DESC, mh.title;

-- Explanation of features:
-- 1. CTE "MovieHierarchy" for recursive fetching of episode relationships.
-- 2. Left joins to incorporate data from multiple tables with various conditions.
-- 3. Window functions for actor count and distinct aggregation of names.
-- 4. Complicated use of SUM/CASENull logic to compute average ratings.
-- 5. HAVING clause to filter results based on a calculated average.
-- 6. Incorporation of string aggregation for actor names in one field.
