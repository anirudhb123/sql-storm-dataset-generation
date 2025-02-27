WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorsForTopMovies AS (
    SELECT 
        a.name AS actor_name,
        tm.movie_title
    FROM 
        TopMovies tm
    INNER JOIN 
        cast_info ci ON ci.movie_id IN (
            SELECT 
                t.id 
            FROM 
                aka_title t 
            WHERE 
                t.title = tm.movie_title AND 
                t.production_year = tm.production_year
        )
    INNER JOIN 
        aka_name a ON a.person_id = ci.person_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    STRING_AGG(afm.actor_name, ', ') AS cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    ActorsForTopMovies afm ON afm.movie_title = tm.movie_title
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.movie_title;
