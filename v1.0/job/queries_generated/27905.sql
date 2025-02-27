WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as movie_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        keyword,
        movie_rank 
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
),
Actors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    a.actor_name,
    a.movie_count
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.id = cc.movie_id
JOIN 
    Actors a ON cc.subject_id = a.id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    a.movie_count DESC;
