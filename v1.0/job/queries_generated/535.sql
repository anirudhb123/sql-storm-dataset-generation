WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id
),
SelectedMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
CompanyDetails AS (
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
    WHERE 
        cn.country_code IS NOT NULL
),
FinalRanking AS (
    SELECT 
        sm.movie_title,
        sm.production_year,
        sm.cast_count,
        COALESCE(cd.company_name, 'Unknown') AS company_name,
        COALESCE(cd.company_type, 'Other') AS company_type
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        CompanyDetails cd ON sm.movie_id = cd.movie_id
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.cast_count,
    fr.company_name,
    fr.company_type
FROM 
    FinalRanking fr
WHERE 
    fr.cast_count > 0
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC;
