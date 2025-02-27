WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.role_rank <= 5
),
CompanyRoleCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS role_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    h.title,
    h.production_year,
    COALESCE(crc.company_count, 0) AS total_companies,
    COALESCE(crc.role_count, 0) AS total_roles,
    string_agg(DISTINCT a.name, ', ') AS actors
FROM 
    HighRankedMovies h
LEFT JOIN 
    CompanyRoleCount crc ON h.movie_id = crc.movie_id
LEFT JOIN 
    cast_info ci ON h.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    h.movie_id, h.title, h.production_year
ORDER BY 
    h.production_year DESC, total_companies DESC;
