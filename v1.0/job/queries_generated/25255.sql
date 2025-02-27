WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    ak.name AS actor_name,
    ct.kind AS role_type
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year DESC;
