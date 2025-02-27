WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title at 
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    JOIN 
        cast_info ci ON at.id = ci.movie_id 
    GROUP BY 
        at.title, at.production_year, k.keyword
),
TopKeywords AS (
    SELECT 
        movie_keyword,
        COUNT(*) AS keyword_frequency
    FROM 
        RankedMovies
    GROUP BY 
        movie_keyword
    ORDER BY 
        keyword_frequency DESC
    LIMIT 10
),
MoviesWithTopKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count
    FROM 
        RankedMovies rm
    JOIN 
        TopKeywords tk ON rm.movie_keyword = tk.movie_keyword
)
SELECT 
    mwt.movie_title,
    mwt.production_year,
    mwt.movie_keyword,
    mwt.cast_count,
    COALESCE(cp.kind, 'Unknown') AS company_type
FROM 
    MoviesWithTopKeywords mwt
LEFT JOIN 
    movie_companies mc ON mwt.movie_title = (SELECT title FROM title WHERE id = mc.movie_id)
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
ORDER BY 
    mwt.cast_count DESC, 
    mwt.production_year DESC;
