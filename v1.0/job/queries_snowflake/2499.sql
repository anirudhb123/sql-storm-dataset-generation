
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
MovieDetails AS (
    SELECT 
        t.title,
        m.info,
        k.keyword
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_info m ON m.movie_id = aka_title.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = aka_title.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title ON aka_title.title = t.title
)
SELECT 
    md.title, 
    COALESCE(md.info, 'No Info') AS details,
    COALESCE(md.keyword, 'No Keywords') AS keywords,
    t.production_year
FROM 
    MovieDetails md
JOIN 
    TopMovies t ON md.title = t.title
ORDER BY 
    t.production_year DESC, md.title ASC;
