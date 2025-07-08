WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
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
        rank <= 3
),
MovieCompanyInfo AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.title, c.name, ct.kind
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mci.company_name, 'No Companies') AS company_name,
        COALESCE(mci.company_type, 'N/A') AS company_type,
        mci.company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieCompanyInfo mci ON tm.title = mci.title
)
SELECT 
    f.title,
    f.production_year,
    f.company_name,
    f.company_type,
    f.company_count
FROM 
    FinalResults f
WHERE 
    f.company_count IS NOT NULL
ORDER BY 
    f.production_year DESC, f.title;
