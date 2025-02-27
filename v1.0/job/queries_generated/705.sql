WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mg.genres, 'No Genre Available') AS genres,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')) AS production_companies_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.movie_id = mg.movie_id
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mg.genres
ORDER BY 
    tm.production_year DESC, total_cast DESC;
