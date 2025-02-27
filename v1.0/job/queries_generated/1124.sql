WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorMovies AS (
    SELECT 
        a.name,
        COUNT(DISTINCT m.id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT m.id) > 3
)
SELECT 
    tm.title,
    tm.production_year,
    am.name AS actor_name,
    am.movies_count,
    COALESCE(NULLIF(tm.cast_count, 0), 'No Cast') AS cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorMovies am ON tm.title = am.name
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
