WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
KeyActors AS (
    SELECT 
        a.name,
        c.movie_id,
        COUNT(*) AS appearance_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, c.movie_id
),
BestActors AS (
    SELECT 
        ka.name,
        SUM(ka.appearance_count) AS total_appearances
    FROM 
        KeyActors ka
    INNER JOIN 
        PopularMovies pm ON ka.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = pm.title AND m.production_year = pm.production_year LIMIT 1)
    GROUP BY 
        ka.name
    HAVING 
        SUM(ka.appearance_count) > 2
)
SELECT 
    ba.name,
    ba.total_appearances,
    COALESCE(pm.actor_count, 0) AS movies_with_top_actors
FROM 
    BestActors ba
LEFT JOIN 
    PopularMovies pm ON ba.total_appearances = pm.actor_count
ORDER BY 
    ba.total_appearances DESC, pm.movies_with_top_actors ASC;
