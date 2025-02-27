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
        a.id, a.title, a.production_year
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
MovieDetails AS (
    SELECT 
        t.title,
        m.info,
        k.keyword
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_info m ON m.movie_id = (SELECT id FROM aka_title WHERE title = t.title LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = t.title LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.title, 
    COALESCE(md.info, 'No Info') AS details,
    COALESCE(md.keyword, 'No Keywords') AS keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title ASC;
