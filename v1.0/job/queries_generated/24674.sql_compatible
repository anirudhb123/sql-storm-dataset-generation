
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),

CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

MovieWithRoleInfo AS (
    SELECT 
        t.title,
        t.production_year,
        ar.movie_count,
        ar.roles,
        cc.company_count
    FROM 
        RankedTitles t
    LEFT JOIN 
        ActorRoleCounts ar ON t.title_id = ar.person_id
    LEFT JOIN 
        CompanyCount cc ON t.title_id = cc.movie_id
)

SELECT 
    mwr.title,
    mwr.production_year,
    COALESCE(mwr.movie_count, 0) AS total_actors, 
    COALESCE(mwr.roles, 'No Roles') AS roles_list,
    COALESCE(mwr.company_count, 0) AS total_companies
FROM 
    MovieWithRoleInfo mwr
WHERE 
    mwr.production_year BETWEEN 2000 AND 2020
    AND (mwr.roles ILIKE '%lead%' OR mwr.roles IS NULL)
ORDER BY 
    mwr.production_year DESC,
    mwr.title ASC
LIMIT 50;
