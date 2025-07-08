
WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_actors
    FROM 
        RankedTitles
    WHERE 
        actor_rank <= 5
)
SELECT 
    t.production_year,
    LISTAGG(t.movie_title, ', ') WITHIN GROUP (ORDER BY t.movie_title) AS top_movies,
    SUM(COALESCE(t.total_actors, 0)) AS total_actors_count
FROM 
    TopMovies t
GROUP BY 
    t.production_year
ORDER BY 
    t.production_year DESC;
