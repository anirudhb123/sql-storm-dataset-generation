WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMoviesByYear AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN tm.total_cast >= 10 THEN 'Large Cast'
            WHEN tm.total_cast BETWEEN 5 AND 9 THEN 'Medium Cast'
            ELSE 'Small Cast' 
        END AS cast_size
    FROM 
        TopMoviesByYear tm
    LEFT JOIN 
        MovieKeywords k ON tm.movie_id = k.movie_id
)
SELECT 
    title,
    production_year,
    keywords,
    cast_size,
    CASE 
        WHEN cast_size = 'Large Cast' THEN 'This film might have significant production resources.'
        WHEN cast_size = 'Medium Cast' AND production_year < 2000 THEN 'A classic film from the past.'
        ELSE 'A unique story awaits you.'
    END AS film_description
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, title;