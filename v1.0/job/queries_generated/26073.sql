WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT i.info, '; ') AS movie_info
    FROM 
        RankedMovies m 
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info i ON m.movie_id = i.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title,
    r.production_year,
    r.total_actors,
    r.actor_names,
    mi.keywords,
    mi.movie_info
FROM 
    RankedMovies r
JOIN 
    MovieInfo mi ON r.movie_id = mi.movie_id
ORDER BY 
    r.production_year DESC, r.total_actors DESC;
