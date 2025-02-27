WITH top_movies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title, at.production_year
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords
FROM 
    top_movies tm
WHERE 
    tm.cast_count > 5
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC
LIMIT 10;

