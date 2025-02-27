
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        tk.keyword,
        mi.info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    title,
    production_year,
    cast_count,
    STRING_AGG(keyword, ', ') AS keywords,
    STRING_AGG(info, ' | ') AS synopsis
FROM 
    MovieDetails
GROUP BY 
    title, production_year, cast_count
ORDER BY 
    cast_count DESC;
