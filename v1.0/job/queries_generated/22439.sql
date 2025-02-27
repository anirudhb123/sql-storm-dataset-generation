WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        a.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        a.title
),
MovieCompanyInfo AS (
    SELECT 
        a.title,
        COALESCE(c.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    h.title,
    h.production_year,
    h.total_cast,
    k.keywords,
    COALESCE(ci.company_name, 'No Company') AS company_name,
    COALESCE(ci.company_type, 'No Type') AS company_type
FROM 
    HighCastMovies h
LEFT JOIN 
    MovieKeywords k ON h.title = k.title
LEFT JOIN 
    MovieCompanyInfo ci ON h.title = ci.title
WHERE 
    h.total_cast > (
        SELECT AVG(total_cast) 
        FROM HighCastMovies
    )
ORDER BY 
    h.production_year DESC,
    h.total_cast DESC;
