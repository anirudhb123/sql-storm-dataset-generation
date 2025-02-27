WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COALESCE(mcc.name, 'Unknown Company') AS production_company,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name mcc ON mc.company_id = mcc.id AND mcc.country_code = 'USA'
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, mcc.name
), RoleSummary AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), RankedMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.production_company,
        md.cast_count,
        md.total_roles,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank_by_cast
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.production_company,
    rm.cast_count,
    rm.total_roles,
    rs.role_name,
    rs.role_count,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year Unknown' 
        ELSE 'Year Known' 
    END AS year_status
FROM 
    RankedMovies rm
LEFT JOIN 
    RoleSummary rs ON rm.movie_id = rs.movie_id
WHERE 
    rm.rank_by_cast <= 10 
ORDER BY 
    rm.cast_count DESC, rs.role_count DESC
LIMIT 50;
