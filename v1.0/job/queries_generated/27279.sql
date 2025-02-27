WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 0
)
SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(DISTINCT an.name, ', ') AS all_actor_names,
    k.keyword AS genre_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.rank, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.rank 
LIMIT 10;
