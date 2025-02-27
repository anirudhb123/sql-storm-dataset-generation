WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
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
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        string_agg(CONCAT(it.info, ': ', mi.info) ORDER BY it.id) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    COALESCE(cd.company_name, 'Unknown') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    mi.info_details
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.title = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.production_year = mi.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
