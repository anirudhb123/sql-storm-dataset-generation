WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ci.note AS role_note
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.title;
