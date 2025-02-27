WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        tm.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
