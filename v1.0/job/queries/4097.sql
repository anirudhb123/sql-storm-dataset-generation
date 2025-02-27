
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    INNER JOIN 
        cast_info c ON t.id = c.movie_id
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
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
    COALESCE(MAX(i.info), 'No Additional Info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info i ON tm.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords_list
ORDER BY 
    tm.production_year DESC, tm.movie_id;
