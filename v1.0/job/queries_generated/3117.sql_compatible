
WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.role_id
), 
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mr.role_count), 0) AS total_roles
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoles mr ON mr.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
    HAVING 
        COALESCE(SUM(mr.role_count), 0) > 10
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        COUNT(DISTINCT c.person_id) AS unique_actors,
        STRING_AGG(char_name.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info c ON tm.movie_id = c.movie_id
    LEFT JOIN 
        aka_name char_name ON c.person_id = char_name.person_id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    md.movie_id,
    md.title,
    md.unique_actors,
    md.actor_names,
    CASE 
        WHEN md.unique_actors IS NULL THEN 'No Actors'
        WHEN md.unique_actors < 5 THEN 'Few Actors'
        ELSE 'Many Actors'
    END AS actor_count_description
FROM 
    MovieDetails md
ORDER BY 
    md.unique_actors DESC;
