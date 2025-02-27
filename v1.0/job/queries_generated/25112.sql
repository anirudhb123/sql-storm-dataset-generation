WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        cast_count 
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.cast_count,
    rc.link_type,
    rc.linked_movie_id
FROM 
    TopMovies tm
LEFT JOIN 
    movie_link rc ON tm.movie_title = (SELECT title FROM title WHERE id = rc.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
