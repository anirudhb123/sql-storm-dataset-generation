
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level,
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ep.id AS movie_id,
        ep.title AS movie_title,
        mh.level + 1 AS level,
        ep.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.movie_id
), 

co_actor AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        STRING_AGG(DISTINCT ak.name, ', ') AS co_actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.person_id, ci.movie_id
), 

studio_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS is_distributor
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 

keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(co.unique_roles, 0) AS unique_roles,
    COALESCE(si.companies, 'None') AS companies,
    COALESCE(kc.total_keywords, 0) AS total_keywords,
    COALESCE(co.co_actor_names, 'None') AS co_actor_names,
    CASE 
        WHEN COALESCE(kc.total_keywords, 0) > 5 THEN 'Highly Keyworded'
        WHEN COALESCE(kc.total_keywords, 0) BETWEEN 1 AND 5 THEN 'Moderately Keyworded'
        ELSE 'No Keywords'
    END AS keyword_category,
    CASE 
        WHEN COALESCE(si.is_distributor, 0) = 1 THEN 'Has Distributor'
        ELSE 'No Distributor'
    END AS distributor_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    co_actor co ON mh.movie_id = co.movie_id
LEFT JOIN 
    studio_info si ON mh.movie_id = si.movie_id
LEFT JOIN 
    keyword_count kc ON mh.movie_id = kc.movie_id
WHERE 
    mh.level = 0 AND 
    (mh.production_year IS NOT NULL AND mh.production_year >= 2000)
ORDER BY 
    mh.production_year DESC,
    COALESCE(co.unique_roles, 0) DESC,
    mh.movie_title;
