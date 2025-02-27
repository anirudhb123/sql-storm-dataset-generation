WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(ci.role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.role_id) DESC) AS role_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.person_id
),
keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
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
    COALESCE(cr.person_count, 0) AS cast_count,
    COALESCE(kw.keyword_list, 'No Keywords') AS keywords,
    STRING_AGG(DISTINCT na.name, ', ') AS actors,
    AVG(CASE WHEN cwr.role_rank > 1 THEN cwr.role_count ELSE NULL END) AS avg_additional_roles
FROM 
    movie_hierarchy mh
LEFT JOIN 
    (SELECT movie_id, COUNT(DISTINCT person_id) AS person_count 
     FROM cast_info 
     GROUP BY movie_id) cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    keywords kw ON mh.movie_id = kw.movie_id
LEFT JOIN 
    cast_with_roles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    aka_name na ON cwr.person_id = na.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cr.person_count, kw.keyword_list
HAVING 
    AVG(CASE WHEN cwr.role_rank > 1 THEN cwr.role_count ELSE NULL END) > 0
ORDER BY 
    mh.production_year DESC, mh.title;
