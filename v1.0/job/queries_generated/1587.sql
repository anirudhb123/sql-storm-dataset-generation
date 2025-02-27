WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
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
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_infos
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(CD.company_name, 'Independent') AS production_company,
    COALESCE(MI.movie_infos, 'No Info Available') AS additional_info
FROM 
    TopMovies t
LEFT JOIN 
    CompanyDetails CD ON t.production_year = t.production_year
LEFT JOIN 
    MovieInfo MI ON t.production_year = MI.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    t.title ASC;
