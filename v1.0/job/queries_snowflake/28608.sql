
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors_list
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        actor_count,
        actors_list,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.movie_title,
    tm.production_year,
    kt.kind AS movie_kind,
    tm.actor_count,
    tm.actors_list
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
