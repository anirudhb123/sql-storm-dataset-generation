WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast = 1
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title AS top_movie_title,
    tm.production_year,
    COALESCE(string_agg(mk.keyword, ', '), 'No keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS unique_people
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.production_year = (SELECT DISTINCT production_year FROM aka_title WHERE title = tm.title)
LEFT JOIN 
    cast_info c ON EXISTS (SELECT 1 FROM aka_title a WHERE a.title = tm.title AND a.id = c.movie_id)
GROUP BY 
    tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 10
ORDER BY 
    tm.production_year DESC;
