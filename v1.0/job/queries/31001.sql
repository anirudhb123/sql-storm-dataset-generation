
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.nr_order = 1 THEN ci.person_id END) AS leading_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.leading_roles, 0) AS leading_roles,
        COALESCE(ks.keywords, 'None') AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON mh.movie_id = ks.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.leading_roles,
    md.keywords,
    CASE 
        WHEN md.total_cast > 0 THEN md.leading_roles * 100.0 / md.total_cast 
        ELSE NULL 
    END AS lead_role_percentage,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.leading_roles DESC) AS rank_per_year
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.leading_roles DESC;
