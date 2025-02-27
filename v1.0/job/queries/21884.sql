WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(NULL AS INTEGER) AS parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title WHERE season_nr IS NULL)
  
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
    WHERE 
        m.season_nr IS NOT NULL
),
movie_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
actor_role_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN cr.role IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type cr ON ci.role_id = cr.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    COALESCE(ars.actor_count, 0) AS actor_count,
    COALESCE(ars.roles_count, 0) AS roles_count,
    CASE 
        WHEN mh.level = 0 THEN 'Feature Film'
        ELSE 'Episode'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_with_keywords mk ON mh.movie_id = mk.movie_id AND mk.keyword_rank = 1
LEFT JOIN 
    actor_role_summary ars ON mh.movie_id = ars.movie_id
WHERE 
    mh.level <= 5
ORDER BY 
    mh.production_year DESC, 
    mh.title;
