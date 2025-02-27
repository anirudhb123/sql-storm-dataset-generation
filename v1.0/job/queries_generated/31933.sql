WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
highest_rated_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS number_of_cast,
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
    HAVING 
        COUNT(ci.person_id) > 3
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(h.number_of_cast, 0) AS number_of_cast,
    COALESCE(h.max_order, 0) AS max_order,
    mk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    highest_rated_cast h ON mh.movie_id = h.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
    AND (h.number_of_cast IS NULL OR h.number_of_cast > 5)
ORDER BY 
    mh.production_year DESC, 
    mh.title;
