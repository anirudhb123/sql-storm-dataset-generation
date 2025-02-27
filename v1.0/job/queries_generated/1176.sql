WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id
),
CompanyStats AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        aka_title a ON mc.movie_id = a.id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title, 
    m.production_year, 
    COALESCE(cs.company_count, 0) AS company_count,
    COALESCE(ki.keywords, 'No keywords') AS keywords,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.title = cs.movie_id
LEFT JOIN 
    KeywordInfo ki ON rm.title = ki.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
