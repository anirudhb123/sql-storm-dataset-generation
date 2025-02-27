
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(MAX(c.nr_order), 0) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
FilteredActors AS (
    SELECT 
        ak.name AS actor_name, 
        MIN(c.nr_order) AS first_appearance
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        TopMovies tm ON c.movie_id = tm.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
)
SELECT 
    tm.title, 
    tm.production_year,
    COUNT(DISTINCT fa.actor_name) AS total_actors,
    STRING_AGG(DISTINCT fa.actor_name, ', ') AS actor_list
FROM 
    TopMovies tm
LEFT JOIN 
    FilteredActors fa ON tm.movie_id = fa.first_appearance
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, total_actors DESC;
