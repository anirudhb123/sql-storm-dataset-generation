
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT akn.name) AS actor_count,
        LISTAGG(DISTINCT akn.name, ', ') WITHIN GROUP (ORDER BY akn.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name akn ON ci.person_id = akn.person_id
    GROUP BY 
        ci.movie_id
),
movie_detail AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.company_names, 'None') AS company_names,
        COALESCE(cas.actor_count, 0) AS actor_count,
        COALESCE(cas.actor_names, 'None') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn,
        DENSE_RANK() OVER (ORDER BY mh.production_year DESC) AS ranked_year
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        company_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        cast_summary cas ON mh.movie_id = cas.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    company_count,
    company_names,
    actor_count,
    actor_names
FROM 
    movie_detail
WHERE 
    (company_count > 1 OR actor_count > 5)
    AND ranked_year = 1
ORDER BY 
    production_year DESC, title;
