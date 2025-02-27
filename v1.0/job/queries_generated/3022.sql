WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.id AS movie_id,
        c.person_id,
        c.role_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        title m ON m.id = c.movie_id
    JOIN 
        role_type r ON r.id = c.role_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON co.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(SUM(CASE WHEN mc.role_name IS NULL THEN 0 ELSE 1 END), 0) AS total_actors,
    STRING_AGG(DISTINCT cm.company_name, ', ') AS production_companies,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON mc.movie_id = rm.id
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = rm.id
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = rm.id
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.title, rm.production_year, mi.info_details
ORDER BY 
    rm.production_year DESC, total_actors DESC;
