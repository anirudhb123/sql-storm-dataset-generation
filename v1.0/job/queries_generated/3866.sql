WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE WHEN r.role LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
), 
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT i.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.total_cast, 0) AS total_cast,
    COALESCE(mc.lead_roles, 0) AS lead_roles,
    COALESCE(cm.total_companies, 0) AS total_companies,
    COALESCE(cm.company_names, 'None') AS company_names,
    COALESCE(mi.info_details, 'No Info') AS info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.production_year >= 2000
    AND (COALESCE(mc.total_cast, 0) + COALESCE(mc.lead_roles, 0)) > 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
