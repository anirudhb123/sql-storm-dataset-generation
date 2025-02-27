WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_name,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(GROUP_CONCAT(ci.role_name || ': ' || ci.role_count), 'No Roles') AS roles,
        COALESCE(LISTAGG(DISTINCT ci.role_name, ', '), 'No Companies') AS role_names,
        COALESCE(MAX(ci.role_count), 0) AS max_role_count,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.roles,
    ci.company_name,
    ci.company_type,
    CASE 
        WHEN md.total_cast_members > 10 THEN 'Large Cast'
        WHEN md.total_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN md.max_role_count > 3 THEN 'Diverse Roles'
        ELSE 'Few Roles'
    END AS role_diversity
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
WHERE 
    md.production_year >= 2000 
    AND md.total_cast_members IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
