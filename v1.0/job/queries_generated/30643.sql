WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_roles AS (
    SELECT
        ci.movie_id,
        ca.person_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        cast_info ci
    JOIN
        aka_name ca ON ci.person_id = ca.person_id
),
company_count AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
info_aggregation AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS aggregated_info
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ac.person_id,
    ac.actor_order,
    COALESCE(cc.company_count, 0) AS total_companies,
    ia.aggregated_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_roles ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    company_count cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    info_aggregation ia ON mh.movie_id = ia.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC, mh.title, ac.actor_order
LIMIT 100;
