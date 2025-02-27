WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cr.actor_name,
        cr.actor_role,
        ci.companies,
        ci.company_count,
        COALESCE(mwi.info, 'No description') AS info
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRoles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        CompanyInfo ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mwi ON mh.movie_id = mwi.movie_id AND mwi.info_type_id = 1 -- assuming 1 is for descriptions
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.actor_role,
    md.companies,
    md.company_count,
    COUNT(DISTINCT md.actor_name) OVER (PARTITION BY md.movie_id) AS unique_actors,
    LENGTH(md.info) AS info_length
FROM 
    MovieDetails md
WHERE 
    exists (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = md.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Action', 'Drama')))
ORDER BY 
    md.production_year DESC, 
    md.title;
