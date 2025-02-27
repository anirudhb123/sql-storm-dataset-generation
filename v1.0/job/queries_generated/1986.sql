WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        title a ON at.movie_id = a.id
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        a.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        mk.keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    GROUP BY 
        tm.title, tm.production_year, mk.keyword
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    COALESCE(md.cast_names, 'No cast information') AS cast_names,
    CASE 
        WHEN md.keyword IS NOT NULL THEN 'Keyword Available'
        ELSE 'No Keyword'
    END AS keyword_status
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
