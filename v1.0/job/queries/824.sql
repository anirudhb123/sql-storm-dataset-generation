WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS company_count
    FROM 
        movie_companies m 
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
),
MoviesWithKeywords AS (
    SELECT 
        kt.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword kt
    JOIN 
        keyword k ON kt.keyword_id = k.id
    GROUP BY 
        kt.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cm.company_name,
    cm.company_type,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.production_year = cm.movie_id
LEFT JOIN 
    MoviesWithKeywords mkw ON rm.production_year = mkw.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
