WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        MIN(mi.info) AS shortest_info
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
FinalDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        cd.company_name,
        cd.company_type,
        mi.shortest_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.title = cd.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.title = mi.movie_id
)
SELECT 
    fd.title,
    fd.production_year,
    COALESCE(fd.company_name, 'Unknown Company') AS company_name,
    COALESCE(fd.company_type, 'Unknown Type') AS company_type,
    fd.shortest_info,
    (SELECT COUNT(*) FROM aka_name an WHERE an.name = fd.title) AS name_count
FROM 
    FinalDetails fd
WHERE 
    fd.production_year IS NOT NULL AND 
    fd.year_rank <= 5
ORDER BY 
    fd.production_year DESC, fd.title ASC;
