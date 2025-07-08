
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ROUND(AVG(mi.info_type_id), 2) AS average_info_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.production_year = mk.movie_id
GROUP BY 
    tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
