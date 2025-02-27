WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        1 AS depth,
        m.title,
        COALESCE(m.prod_year, 0) AS production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mh.depth + 1,
        a.title AS title,
        COALESCE(a.production_year, 0) AS production_year,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(mi.info::numeric) FILTER (WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS average_rating,
    MAX(mh.depth) AS max_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year > 2000 
    AND c.person_role_id IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    average_rating DESC NULLS LAST,
    actor_count DESC;

