
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY m.info_type_id DESC) AS rank,
        a.movie_id
    FROM 
        aka_title a
    JOIN 
        movie_info m ON a.movie_id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        movie_id
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        c.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    ARRAY_AGG(DISTINCT cd.company_name) AS companies,
    COUNT(DISTINCT mi.info) AS info_count,
    COALESCE(SUM(CASE WHEN LENGTH(mi.info) > 50 THEN 1 ELSE 0 END), 0) AS long_info_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
WHERE 
    tm.production_year >= 2000
AND 
    (mi.info_type_id IS NULL OR mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%drama%'))
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
