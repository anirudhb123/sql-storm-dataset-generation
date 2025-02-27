WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        mh.level + 1,
        mh.path || e.title
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_info_cte AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        mci.num_cast, 
        mci.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mci.num_cast DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info_cte mci ON mt.id = mci.movie_id
)
SELECT 
    mh.title AS episode_title,
    mh.level,
    mh.path,
    md.production_year,
    COALESCE(md.num_cast, 0) AS number_of_cast,
    md.cast_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_details md ON mh.movie_id = md.title
WHERE 
    mh.level = 1
    AND md.rn <= 3
ORDER BY 
    mh.production_year DESC,
    mh.title
LIMIT 100;
