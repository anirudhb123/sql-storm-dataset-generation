WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    WHERE 
        a.production_year IS NOT NULL
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
        year_rank <= 5
), 
GenreKeywords AS (
    SELECT 
        k.keyword,
        m.title
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
)
SELECT 
    tm.title AS Top_Movie,
    tm.production_year AS Production_Year,
    COALESCE(GROUP_CONCAT(DISTINCT g.keyword ORDER BY g.keyword), 'No Keywords') AS Associated_Keywords
FROM 
    TopMovies tm
LEFT JOIN 
    GenreKeywords g ON tm.title = g.title
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
