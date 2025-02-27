WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_order
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_order <= 5 
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT mi.info ORDER BY mi.note), 'No info') AS additional_info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.production_year = mi.movie_id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    m.title, 
    m.production_year,
    cd.company_name,
    cd.company_type,
    mi.additional_info
FROM 
    TopMovies m
LEFT JOIN 
    CompanyDetails cd ON m.title = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON m.title = mi.title AND m.production_year = mi.production_year
WHERE 
    cd.company_name IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    m.title;
