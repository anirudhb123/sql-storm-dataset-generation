
WITH MovieCounts AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast_members,
        SUM(CASE WHEN ca.note IS NULL THEN 1 ELSE 0 END) AS cast_members_without_note
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.movie_id
    GROUP BY 
        ca.movie_id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

RatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        at.production_year,
        COALESCE(SUM(mi.info_type_id), 0) AS info_count
    FROM 
        title m
    LEFT JOIN 
        aka_title at ON m.id = at.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, at.production_year
    HAVING 
        COALESCE(SUM(mi.info_type_id), 0) > 0
)

SELECT 
    rm.title,
    rm.production_year,
    mc.total_cast_members,
    mc.cast_members_without_note,
    cm.company_name,
    cm.company_type
FROM 
    RatedMovies rm
JOIN 
    MovieCounts mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 100;
