
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        MAX(mo.info) AS movie_overview
    FROM 
        title m
    JOIN 
        movie_info mo ON m.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'overview')
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count, 
        cast_names,
        movie_overview,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.actor_count,
    t.cast_names,
    t.movie_overview
FROM 
    TopMovies t
WHERE 
    t.rank <= 10
ORDER BY 
    t.actor_count DESC;
