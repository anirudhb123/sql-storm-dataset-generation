WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
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
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mii.info, '; ') AS info_summary
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY 
        mi.movie_id
   ),
keywords_summary AS (
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
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.role_count,
    ms.info_summary,
    ks.keyword_list,
    CASE 
        WHEN cs.total_cast IS NULL THEN 'No Cast Information'
        WHEN cs.role_count = 0 THEN 'No Roles Assigned'
        ELSE 'Complete Data Available'
    END AS cast_info_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_statistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary ms ON mh.movie_id = ms.movie_id
LEFT JOIN 
    keywords_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.level <= 2 
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;
