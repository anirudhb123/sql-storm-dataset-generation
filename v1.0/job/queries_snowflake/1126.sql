
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopYearMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year, 
        total_cast 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 3
),
CompanyMovies AS (
    SELECT 
        m.movie_id, 
        m.company_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_infos
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title AS movie_title, 
    tm.production_year, 
    COALESCE(cm.company_name, 'Unknown') AS company_name,
    COALESCE(cm.company_type, 'N/A') AS company_type,
    COALESCE(mi.movie_infos, 'No Info') AS additional_info
FROM 
    TopYearMovies tm
LEFT JOIN 
    CompanyMovies cm ON tm.title_id = cm.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.title_id = mi.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
