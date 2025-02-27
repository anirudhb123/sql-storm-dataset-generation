
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
), 
TopMovies AS (
    SELECT * FROM RankedMovies WHERE rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        ak.name AS actor_name, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    GROUP BY 
        tm.title, tm.production_year, ak.name
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    md.keyword_count
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.keyword_count
HAVING 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
