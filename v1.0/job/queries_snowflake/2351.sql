WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInformation AS (
    SELECT 
        t.title, 
        t.production_year, 
        cm.company_name,
        mi.info AS movie_info
    FROM 
        TopMovies t
    JOIN 
        CompanyMovies cm ON t.production_year = cm.movie_id
    LEFT JOIN 
        movie_info mi ON t.title = mi.info
)
SELECT 
    mi.title,
    mi.production_year,
    mi.company_name,
    COALESCE(mi.movie_info, 'No info available') AS movie_info,
    CASE 
        WHEN mi.company_name IS NULL THEN 'No production company'
        ELSE 'Production company listed'
    END AS company_status
FROM 
    MovieInformation mi
ORDER BY 
    mi.production_year DESC, 
    mi.title;
