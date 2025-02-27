WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.movie_id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON mc.movie_id = at.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    WHERE 
        cn.country_code = 'USA'
),
DetailedMovieInfo AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        fc.company_name, 
        fc.company_type,
        rt.cast_count,
        ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.cast_count DESC) AS rn
    FROM 
        RankedTitles rt
    JOIN 
        FilteredCompanies fc ON fc.movie_id = rt.movie_id
)
SELECT 
    title,
    production_year,
    company_name,
    company_type,
    cast_count,
    CASE 
        WHEN cast_count > 5 THEN 'Large Cast'
        WHEN cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    DetailedMovieInfo
WHERE 
    rn <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
