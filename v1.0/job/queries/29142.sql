WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    aliases,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, cast_count DESC;