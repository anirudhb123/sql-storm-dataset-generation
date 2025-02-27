
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors_names,
        movie_keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors_names,
    tm.movie_keywords
FROM 
    TopMovies AS tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year;
