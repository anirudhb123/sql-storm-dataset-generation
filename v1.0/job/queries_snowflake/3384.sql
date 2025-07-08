
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
FilteredCompanies AS (
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
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS actors_count,
    LISTAGG(DISTINCT co.company_name, ', ') WITHIN GROUP (ORDER BY co.company_name) AS production_companies,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) > 2 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    MAX(m.production_year) OVER () AS latest_production_year
FROM 
    RankedMovies m
LEFT JOIN 
    complete_cast cc ON m.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    FilteredCompanies co ON cc.movie_id = co.movie_id
WHERE 
    m.year_rank <= 5
GROUP BY 
    m.title, m.production_year, latest_production_year
ORDER BY 
    m.production_year DESC, actors_count DESC;
