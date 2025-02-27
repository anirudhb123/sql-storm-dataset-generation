WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
GenreCount AS (
    SELECT 
        movie_id,
        COUNT(genre) AS genre_count
    FROM 
        MovieGenres
    GROUP BY 
        movie_id
),
TopMovies AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(gc.genre_count, 0) AS total_genres,
        COALESCE(mr.total_actors, 0) AS total_actors,
        mr.actor_names
    FROM 
        aka_title m
    LEFT JOIN 
        GenreCount gc ON m.id = gc.movie_id
    LEFT JOIN 
        MovieRoles mr ON m.id = mr.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    tm.title,
    tm.total_genres,
    tm.total_actors,
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.total_genres > 2 AND
    tm.total_actors > (SELECT AVG(total_actors) FROM MovieRoles)
ORDER BY 
    tm.total_genres DESC, 
    tm.total_actors DESC;
