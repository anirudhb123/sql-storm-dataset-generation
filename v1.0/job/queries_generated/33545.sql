WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Top-level movies

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id  -- Joining episodes to their parent
),

movie_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),

keyword_aggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

detailed_movie_info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(kr.keywords, 'No Keywords') AS keywords,
        COALESCE(r.role, 'No Roles') AS roles,
        mh.level,
        ROW_NUMBER() OVER(PARTITION BY m.movie_id ORDER BY r.role_count DESC) AS role_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_roles r ON mh.movie_id = r.movie_id
    LEFT JOIN 
        keyword_aggregation kr ON mh.movie_id = kr.movie_id
)

SELECT 
    dmi.title AS movie_title,
    dmi.production_year,
    dmi.keywords,
    dmi.roles,
    dmi.level,
    CASE 
        WHEN dmi.roles IS NOT NULL THEN 'Has Roles'
        ELSE 'No Roles'
    END AS role_presence,
    dmi.role_rank
FROM 
    detailed_movie_info dmi
WHERE 
    dmi.production_year >= 2000 
    AND dmi.level <= 2  -- Limit to main movies and their direct episodes
ORDER BY 
    dmi.production_year DESC, 
    dmi.role_rank
LIMIT 50;
