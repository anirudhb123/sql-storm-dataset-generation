WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT an.name) AS cast_names,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC;
