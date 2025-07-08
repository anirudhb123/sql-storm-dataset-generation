
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies
    FROM 
        cast_info AS c
    JOIN 
        title AS t ON c.movie_id = t.id
    WHERE 
        c.nr_order = 1
    GROUP BY 
        c.person_id
),
PersonWithMostMovies AS (
    SELECT 
        a.person_id,
        a.movie_count,
        a.movies,
        RANK() OVER (ORDER BY a.movie_count DESC) AS movie_rank
    FROM 
        ActorMovies AS a
)
SELECT 
    p.id AS person_id,
    ak.name AS aka_name,
    COALESCE(r.title_id, 0) AS title_id,
    COALESCE(r.title, 'No Title') AS title,
    COALESCE(pwm.movie_count, 0) AS total_movies,
    COALESCE(pwm.movies, 'No Movies') AS movies_list,
    CASE 
        WHEN pwm.movie_rank <= 10 THEN 'Top Actor'
        ELSE 'Regular Actor'
    END AS actor_type
FROM 
    person_info AS p
LEFT JOIN 
    aka_name AS ak ON p.person_id = ak.person_id
LEFT JOIN 
    RankedTitles AS r ON r.rn = 1 AND r.production_year = EXTRACT(YEAR FROM '2024-10-01'::DATE)
LEFT JOIN 
    PersonWithMostMovies AS pwm ON pwm.person_id = p.person_id
WHERE 
    ak.name IS NOT NULL OR pwm.movie_count > 0
ORDER BY 
    total_movies DESC, ak.name;
