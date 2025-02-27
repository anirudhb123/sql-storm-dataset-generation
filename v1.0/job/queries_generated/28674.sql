WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS person_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        at.id, at.title, at.production_year, ak.name
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    ORDER BY 
        production_year DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_title = (SELECT at.title FROM aka_title at WHERE at.id = ci.movie_id)
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = tm.movie_title)
    GROUP BY 
        tm.movie_title, tm.production_year
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    keywords
FROM 
    MovieDetails
ORDER BY 
    production_year DESC;
