WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        DENSE_RANK() OVER (ORDER BY actor_count DESC) AS rating
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.actors,
    f.rating
FROM 
    FilteredMovies f
WHERE 
    f.actor_count > 5
ORDER BY 
    f.rating;