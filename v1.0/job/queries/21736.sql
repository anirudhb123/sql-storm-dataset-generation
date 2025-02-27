WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
MovieInfoAndKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        mi.info,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.title = mi.info
    LEFT JOIN 
        movie_keyword mk ON m.production_year = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year,
        STRING_AGG(DISTINCT info, '; ') AS movie_info,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        MovieInfoAndKeywords
    WHERE 
        info IS NOT NULL AND keyword IS NOT NULL
    GROUP BY 
        title, production_year
)

SELECT 
    fm.title,
    fm.production_year,
    fm.movie_info,
    fm.keywords,
    COALESCE(NULLIF(SUBSTRING(fm.keywords FROM '[^,]+'), ''), 'No Keywords') AS processed_keywords,
    COUNT(*) OVER () AS total_movies
FROM 
    FilteredMovies fm
WHERE 
    LENGTH(fm.title) > 10 
ORDER BY 
    fm.production_year DESC, 
    fm.title;