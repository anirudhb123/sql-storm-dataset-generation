WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
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
        rank <= 10
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    tm.cast_count,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id 
JOIN 
    aka_name p ON p.person_id = ci.person_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.movie_keyword, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

This SQL query ranks movies based on the count of unique cast members, associates them with keywords, and provides a list of the top 10 movies with their corresponding keywords and cast names. It demonstrates string processing through the use of `STRING_AGG`.
