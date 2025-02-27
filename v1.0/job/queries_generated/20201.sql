WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::TEXT AS parent_movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_movie_title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COUNT(*) OVER (PARTITION BY a.id) AS total_movies_involved,
    AVG(mh.depth) AS avg_link_depth,
    COUNT(DISTINCT mk.keyword) AS distinct_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords,
    CASE 
        WHEN a.surname_pcode IS NULL THEN 'Unknown'
        ELSE a.surname_pcode
    END AS surname_code,
    COALESCE(mo.info, 'No additional info') AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mo ON t.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
WHERE 
    t.production_year > 2000
    AND (mh.depth IS NULL OR mh.depth <= 3)
    AND EXISTS (
        SELECT 
            1 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = t.id 
            AND mi.info ILIKE '%Oscar%'
    )
GROUP BY 
    a.name, t.title, mh.production_year, a.id, mo.info
ORDER BY 
    movie_title ASC, avg_link_depth DESC;
