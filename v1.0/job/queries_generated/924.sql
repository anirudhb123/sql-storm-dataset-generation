WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
), 
TopMovies AS (
    SELECT 
        title, production_year
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ak.name AS actor_name,
    ak.imdb_index AS actor_imdb_index
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT at2.title FROM aka_title at2 WHERE at2.production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT at3.id FROM aka_title at3 WHERE at3.title = tm.title LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT at4.id FROM aka_title at4 WHERE at4.title = tm.title LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.title ASC;
