WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(tm.cast_names, 'No Cast Information') AS cast_information,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id 
WHERE 
    tm.production_year >= (SELECT MIN(production_year) FROM aka_title)
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title ASC;
