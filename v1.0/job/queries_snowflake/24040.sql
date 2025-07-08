WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth,
        CAST(NULL AS INTEGER) AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1,
        mh.movie_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastInfoCTE AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_order,
        CASE 
            WHEN ci.note IS NOT NULL THEN ci.note
            ELSE 'No Note' 
        END AS note_info
    FROM 
        cast_info ci
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        mc.movie_id,
        c.name,
        ct.kind
    HAVING 
        COUNT(DISTINCT m.id) > 1
)

SELECT 
    mh.title,
    mh.production_year,
    mh.depth,
    COALESCE(ci.role_order, -1) AS role_order,
    ci.note_info,
    ci.person_id,
    ci.movie_id,
    ci.role_id,
    COALESCE(cinfo.company_name, 'Independent') AS producing_company,
    cinfo.company_type,
    cinfo.movie_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfoCTE ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    CompanyInfo cinfo ON mh.movie_id = cinfo.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (ci.role_id IS NULL OR ci.role_id IN (SELECT role_id FROM role_type WHERE role LIKE 'Actor%' OR role LIKE 'Director%'))
ORDER BY 
    mh.production_year DESC,
    mh.title,
    role_order NULLS LAST,
    cinfo.movie_count DESC;
