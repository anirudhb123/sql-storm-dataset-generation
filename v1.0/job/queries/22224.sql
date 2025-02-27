WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 3
),
CompanyDetails AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        CASE 
            WHEN c.country_code IS NULL THEN 'Unknown'
            ELSE c.country_code
        END AS country_code_lo
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    INNER JOIN 
        aka_title m ON mc.movie_id = m.id
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    DISTINCT t.title,
    t.production_year,
    coalesce(cd.company_name, 'No Company') AS company_name,
    coalesce(cd.company_type, 'No Type') AS company_type,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN '2000s'
        WHEN t.production_year < 2000 THEN '90s or earlier'
        ELSE '2010s or later'
    END AS decade_group
FROM 
    TopMovies t
LEFT JOIN 
    CompanyDetails cd ON t.title = cd.title
LEFT JOIN 
    MoviesWithKeywords mk ON t.title = mk.title
WHERE 
    (t.production_year IS NOT NULL AND t.production_year > 1990)
    AND (cd.country_code_lo IS NULL OR cd.country_code_lo <> 'Unknown')
ORDER BY 
    t.production_year DESC,
    t.title ASC;
