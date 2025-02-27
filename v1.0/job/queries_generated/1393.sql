WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        title ti ON t.id = ti.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
RecentHits AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
CompanyDetails AS (
    SELECT 
        m.title, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        aka_title m
    INNER JOIN 
        movie_companies mc ON m.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rh.title, 
    rh.production_year, 
    rh.cast_count, 
    cd.company_name, 
    cd.company_type
FROM 
    RecentHits rh
LEFT JOIN 
    CompanyDetails cd ON rh.title = cd.title
WHERE 
    cd.company_name IS NOT NULL
ORDER BY 
    rh.production_year DESC, rh.cast_count DESC;
