WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        RankedMovies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.kind_id,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies
FROM 
    RankedMovies r
LEFT JOIN 
    MovieWithKeywords mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON r.movie_id = mc.movie_id
WHERE 
    r.rank <= 5 AND
    (r.kind_id = 1 OR r.kind_id IS NULL)
ORDER BY 
    r.production_year DESC;
