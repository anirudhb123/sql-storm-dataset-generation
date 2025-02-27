WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
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
        m.id AS movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    INNER JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(p.info, 'No info available') AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
LEFT JOIN 
    person_info p ON p.person_id IN (
        SELECT 
            c.person_id 
        FROM 
            cast_info c 
        WHERE 
            c.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
    )
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
