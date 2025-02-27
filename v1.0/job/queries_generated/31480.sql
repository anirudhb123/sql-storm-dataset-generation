WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL -- Top-level movies

    UNION ALL

    SELECT 
        mt2.id, 
        mt2.title, 
        mt2.production_year, 
        mh.level + 1
    FROM 
        aka_title mt2
    JOIN 
        movie_hierarchy mh ON mt2.episode_of_id = mh.movie_id
),
cast_ranked AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(comp.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(cs.company_count, 0) AS company_count,
    cs.companies,
    actor_names.actor_name
FROM 
    movie_hierarchy mh
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS actor_count 
     FROM 
        cast_info 
     GROUP BY 
        movie_id) cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    company_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    cast_ranked actor_names ON mh.movie_id = actor_names.movie_id AND actor_names.actor_rank <= 3
WHERE 
    mh.production_year >= 2000 AND
    (mh.title LIKE '%Award%' OR mh.title LIKE '%Nominee%')
ORDER BY 
    mh.production_year DESC, mh.title;
