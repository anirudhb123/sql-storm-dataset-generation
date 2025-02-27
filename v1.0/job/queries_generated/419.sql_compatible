
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_info m ON m.movie_id = a.id
    WHERE 
        m.info_type_id IN (SELECT id FROM info_type WHERE info = 'BoxOffice')
    GROUP BY 
        a.title, a.production_year, a.id
),

TopMovies AS (
    SELECT 
        title, 
        production_year,
        cast_count
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 5
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;
