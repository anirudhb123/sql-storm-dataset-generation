WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 
MovieGenres AS (
    SELECT 
        m.id AS movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
), 
CompanyInfo AS (
    SELECT 
        m.id AS movie_id, 
        COALESCE(cn.name, 'Unknown') AS company_name,
        COUNT(mc.id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.id, cn.name
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    mg.keywords, 
    ci.company_name, 
    ci.company_count
FROM 
    RankedMovies rm
JOIN 
    MovieGenres mg ON rm.title = mg.title
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.movie_id
WHERE 
    rm.year_rank <= 5 AND 
    (ci.company_count > 0 OR ci.company_name IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
