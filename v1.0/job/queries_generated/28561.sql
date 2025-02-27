WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
PersonMovieStats AS (
    SELECT 
        p.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT m.movie_title, ', ') AS movies_list
    FROM 
        cast_info c
    JOIN 
        aka_name n ON n.person_id = c.person_id
    JOIN 
        RankedMovies m ON m.movie_id = c.movie_id
    JOIN 
        role_type r ON r.id = c.person_role_id
    WHERE 
        r.role = 'actor'  -- Filter by actor role
    GROUP BY 
        p.id, n.name
),
TopActors AS (
    SELECT 
        person_id,
        person_name,
        total_movies,
        movies_list,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        PersonMovieStats
)
SELECT 
    a.rank,
    a.person_name,
    a.total_movies,
    a.movies_list,
    m.production_year,
    STRING_AGG(DISTINCT m.movie_title, ', ') AS movies_in_year
FROM 
    TopActors a
JOIN 
    cast_info c ON c.person_id = a.person_id
JOIN 
    RankedMovies m ON m.movie_id = c.movie_id
WHERE 
    a.rank <= 10  -- Top 10 actors
GROUP BY 
    a.rank, a.person_name, a.total_movies, m.production_year
ORDER BY 
    a.rank, m.production_year DESC;
