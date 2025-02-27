WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS movie_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(*) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
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
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mo.cast_names, 'No Cast') AS cast_list,
    COALESCE(ci.company_name, 'No Company') AS production_company,
    CASE 
        WHEN mo.total_cast > 10 THEN 'Large Cast'
        WHEN mo.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mo ON rm.id = mo.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.id = ci.movie_id
WHERE 
    rm.movie_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
