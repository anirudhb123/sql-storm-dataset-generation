WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(b.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(b.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
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
DetailedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(c.company_name, ', ') AS production_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails c ON rm.title = (
            SELECT 
                t.title 
            FROM 
                title t 
            WHERE 
                t.id = rm.id 
        )
    WHERE 
        rm.year_rank <= 5
    GROUP BY
        rm.title, rm.production_year, rm.cast_count
)
SELECT 
    dm.title,
    dm.production_year,
    dm.cast_count,
    dm.production_companies,
    CASE 
        WHEN dm.cast_count IS NULL THEN 'No cast information available'
        ELSE 'Cast information available'
    END AS cast_info_status
FROM 
    DetailedMovies dm
ORDER BY 
    dm.production_year DESC, dm.cast_count DESC;
