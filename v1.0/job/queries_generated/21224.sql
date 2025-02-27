WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.hierarchy_level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies_list
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ms.actor_count,
    ms.role_count,
    ms.actors_list,
    ks.keywords_list,
    cs.companies_list,
    CASE 
        WHEN mh.hierarchy_level = 1 THEN 'Original'
        WHEN mh.hierarchy_level > 1 THEN 'Episode'
        ELSE 'Unknown' 
    END AS movie_type,
    COALESCE(ms.actor_count, 0) + COALESCE(ks.keywords_list, '')::int AS performance_metric
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary ms ON mh.movie_id = ms.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    company_info cs ON mh.movie_id = cs.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    performance_metric DESC NULLS LAST;
