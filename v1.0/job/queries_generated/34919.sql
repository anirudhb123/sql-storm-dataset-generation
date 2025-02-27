WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ep.id AS movie_id,
        ep.title AS movie_title,
        ep.production_year,
        mh.level + 1
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.movie_id
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS cast_with_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

title_with_roles AS (
    SELECT 
        at.title,
        ct.kind AS role_kind,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        at.title, ct.kind
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cs.total_cast,
    cs.cast_with_notes,
    twr.role_kind,
    twr.role_count,
    CASE 
        WHEN cs.total_cast > 0 THEN ROUND((cs.cast_with_notes::decimal / cs.total_cast) * 100, 2)
        ELSE 0 
    END AS percentage_cast_with_notes
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    title_with_roles twr ON mh.movie_title = twr.title
WHERE 
    mh.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    mh.production_year DESC, mh.movie_title;

-- This query evaluates the movies in a hierarchical structure while analyzing the cast and roles.
-- It summarizes key information such as total cast, number of cast members with notes,
-- and calculates the percentage of cast members with notes relative to the total cast.
-- The results are filtered to show only movies produced after the average year,
-- sorted by production year and movie title.
