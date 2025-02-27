
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS movie_rank
    FROM 
        aka_title at
    JOIN 
        cast_info cc ON at.movie_id = cc.movie_id
    WHERE 
        at.production_year >= 2000 
        AND at.title IS NOT NULL
    GROUP BY 
        at.title, at.production_year
), 
PopularMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 10
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        cc.movie_id, 
        STRING_AGG(DISTINCT rt.role, ', ') AS roles 
    FROM 
        cast_info cc
    JOIN 
        role_type rt ON cc.role_id = rt.id
    GROUP BY 
        cc.movie_id
)
SELECT 
    pm.title,
    pm.production_year,
    cd.company_name,
    cd.company_type,
    cr.roles,
    NULLIF((
        SELECT COUNT(DISTINCT cc.person_id) 
        FROM cast_info cc 
        JOIN aka_title at ON cc.movie_id = at.movie_id 
        WHERE at.title = pm.title AND at.production_year = pm.production_year), 0) AS non_null_cast_count,
    COALESCE(cr.roles, 'No roles assigned') AS roles_display
FROM 
    PopularMovies pm
LEFT JOIN 
    CompanyDetails cd ON pm.production_year = cd.movie_id
LEFT JOIN 
    CastRoles cr ON pm.production_year = cr.movie_id
WHERE 
    COALESCE((
        SELECT COUNT(DISTINCT cc.person_id) 
        FROM cast_info cc 
        JOIN aka_title at ON cc.movie_id = at.movie_id 
        WHERE at.title = pm.title AND at.production_year = pm.production_year), 0) > 0
ORDER BY 
    pm.production_year DESC, pm.title;
