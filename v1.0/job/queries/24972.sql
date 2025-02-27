WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rn,
        COUNT(*) OVER (PARTITION BY at.production_year) AS movie_count
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        MAX(rt.role) AS dominant_role,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT ci.movie_id) FILTER (WHERE rt.role IS NOT NULL) AS roles_with_movies
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name || ' (' || ct.kind || ')', '; ') AS companies_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
TitleWithCompany AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        mc.companies_info,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC), -1) AS company_row_num
    FROM 
        aka_title at
    LEFT JOIN 
        MovieCompanyDetails mc ON at.id = mc.movie_id
)

SELECT 
    tw.title_id,
    tw.title,
    tw.production_year,
    tw.companies_info,
    ac.total_movies,
    ac.dominant_role,
    ac.roles,
    tw.company_row_num
FROM 
    TitleWithCompany tw
JOIN 
    ActorRoleCounts ac ON tw.title_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT id FROM aka_name WHERE name LIKE '%Smith%'))
WHERE 
    tw.production_year = (SELECT MAX(production_year) FROM aka_title) 
    AND tw.companies_info IS NOT NULL
ORDER BY 
    tw.production_year DESC,
    tw.title;