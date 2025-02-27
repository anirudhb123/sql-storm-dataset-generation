
WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
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
        a.title, 
        k.keyword 
    FROM 
        TopMovies t 
    JOIN 
        aka_title a ON t.title = a.title 
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
)
SELECT 
    mk.title,
    STRING_AGG(mk.keyword, ', ') AS keywords,
    COALESCE((SELECT COUNT(*) 
              FROM movie_info mi 
              WHERE mi.movie_id = a.id 
              AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')), 0) AS genre_count
FROM 
    MovieKeywords mk
JOIN 
    aka_title a ON mk.title = a.title
GROUP BY 
    mk.title, a.id
ORDER BY 
    genre_count DESC, mk.title;
