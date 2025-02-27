WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mm.id, 
        mm.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, cast_roles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(cc.kind) AS max_role
    FROM 
        cast_info ci
    LEFT JOIN 
        comp_cast_type cc ON ci.person_role_id = cc.id
    GROUP BY 
        ci.movie_id
)
, movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
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
    mh.level,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(mk.keyword_list, 'No keywords') AS keywords,
    CASE 
        WHEN cr.total_cast > 10 THEN 'Large Cast'
        WHEN cr.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN mk.keyword_list LIKE '%Action%' THEN 'Action Movie'
        WHEN mk.keyword_list LIKE '%Drama%' THEN 'Drama Movie'
        ELSE 'Other Genre'
    END AS genre_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = (SELECT MAX(level) FROM movie_hierarchy)
ORDER BY
    mh.title ASC,
    cr.total_cast DESC NULLS LAST;
