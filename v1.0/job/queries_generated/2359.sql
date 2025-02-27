WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        num_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyMovies AS (
    SELECT 
        cm.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies cm
    INNER JOIN 
        company_name cn ON cm.company_id = cn.id
    INNER JOIN 
        company_type ct ON cm.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.movie_title,
    tm.num_cast,
    cm.company_name,
    cm.company_type,
    mi.movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cm ON tm.movie_title = (SELECT at.title FROM aka_title at WHERE at.id = cm.movie_id)
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = tm.movie_title)
ORDER BY 
    tm.num_cast DESC, tm.movie_title;
