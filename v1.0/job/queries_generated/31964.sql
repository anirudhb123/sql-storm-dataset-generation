WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ci.person_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
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
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(pr.person_id, 'No person') AS person_id,
    COALESCE(pr.distinct_roles, 0) AS total_distinct_roles,
    COALESCE(pr.roles, 'No Roles') AS role_list,
    COALESCE(mci.num_companies, 0) AS total_companies,
    COALESCE(mci.companies, 'No Companies') AS company_list,
    CASE 
        WHEN mh.level > 1 THEN 'Sequel'
        ELSE 'Original'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    PersonRoles pr ON mh.movie_id = pr.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;
