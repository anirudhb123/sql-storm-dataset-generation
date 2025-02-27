WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
cast_with_role AS (
    SELECT 
        ci.movie_id,
        ai.name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
top_cast AS (
    SELECT 
        cw.movie_id,
        STRING_AGG(cw.name, ', ') AS top_actors,
        MAX(cw.role_rank) AS top_rank
    FROM 
        cast_with_role cw
    WHERE 
        cw.role_rank <= 3
    GROUP BY 
        cw.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    COALESCE(tc.top_actors, 'No Cast') AS top_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*)
        FROM movie_info mi 
        WHERE mi.movie_id = mh.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    top_cast tc ON mh.movie_id = tc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.title;
