
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON mh.movie_id = e.episode_of_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
combined_data AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cr.role_name, 'Unknown') AS role_name,
        COALESCE(cr.role_count, 0) AS role_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.level,
        CASE 
            WHEN mh.production_year > 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS film_category
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_roles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.role_name,
    cd.role_count,
    cd.keywords,
    cd.level,
    cd.film_category
FROM 
    combined_data cd
WHERE 
    cd.role_count > 0 OR cd.keywords <> 'No Keywords'
ORDER BY 
    cd.production_year DESC, 
    cd.title;
