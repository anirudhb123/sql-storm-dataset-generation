WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year AS year,
        NULL::integer AS parent_id,
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
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(ci.nr_order) AS average_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
title_info AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COALESCE(mi.info, 'No Info') AS info,
        COALESCE(ki.keyword, 'No Keywords') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
),
final_results AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.year,
        ts.actor_count,
        ts.average_order,
        ti.info,
        ti.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_statistics ts ON mh.movie_id = ts.movie_id
    LEFT JOIN 
        title_info ti ON mh.movie_id = ti.title_id
)

SELECT 
    fr.movie_title,
    fr.year,
    fr.actor_count,
    fr.average_order,
    CASE 
        WHEN fr.average_order IS NULL THEN 'No Cast Order'
        ELSE CASE 
            WHEN fr.average_order < 5 THEN 'Low Order'
            WHEN fr.average_order BETWEEN 5 AND 15 THEN 'Medium Order'
            ELSE 'High Order'
        END
    END AS order_description,
    COALESCE(fr.info, 'Information Missing') AS movie_info,
    REGEXP_REPLACE(COALESCE(fr.keywords, ''), '[ ]+', ', ') AS formatted_keywords
FROM 
    final_results fr
WHERE 
    fr.year = (SELECT MAX(year) FROM final_results)
ORDER BY 
    fr.actor_count DESC NULLS LAST, 
    fr.movie_title ASC;
