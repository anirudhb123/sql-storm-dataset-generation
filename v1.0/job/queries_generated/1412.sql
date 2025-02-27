WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    WHERE 
        title.production_year IS NOT NULL
    GROUP BY 
        title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    COALESCE(ak.name, 'Unknown') AS main_actor,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_title = (
        SELECT title.title 
        FROM title 
        WHERE title.id = ci.movie_id
    )
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_title, tm.production_year, tm.cast_count, ak.name
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
