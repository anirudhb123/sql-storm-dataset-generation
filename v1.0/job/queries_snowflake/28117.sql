
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        RANK() OVER (ORDER BY actor_count DESC) AS rank 
    FROM 
        RankedMovies
)
SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    mci.info AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mci ON tm.movie_id = mci.movie_id
WHERE 
    tm.rank <= 10 
    AND mci.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
ORDER BY 
    tm.rank;
