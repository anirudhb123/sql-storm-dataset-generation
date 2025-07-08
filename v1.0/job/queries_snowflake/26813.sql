
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
DirectorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count,
        AVG(ci.nr_order) AS average_order
    FROM 
        movie_companies c
    JOIN 
        cast_info ci ON c.movie_id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        r.role = 'Director'
    GROUP BY 
        c.movie_id
),
FinalResults AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.movie_keyword,
        tm.cast_count,
        dm.director_count,
        dm.average_order
    FROM 
        TopMovies tm
    LEFT JOIN 
        DirectorMovies dm ON dm.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    cast_count,
    director_count,
    average_order
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_count DESC;
