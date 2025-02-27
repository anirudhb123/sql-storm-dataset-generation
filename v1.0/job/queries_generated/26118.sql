WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_info m ON a.movie_id = m.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres')
),
TopActors AS (
    SELECT 
        c.movie_id,
        n.name AS actor_name,
        COUNT(c.person_id) AS appearances
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id, n.name
    HAVING 
        COUNT(c.person_id) > 3
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    ra.actor_name,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ra ON rm.movie_id = ra.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, ra.appearances DESC;

This SQL query benchmarks string processing by constructing a complex query that achieves the following:
1. Identifies the top 5 movies from the last few years based on a ranking of their production year.
2. Counts the number of appearances of actors in the cast and filters for actors that have appeared in more than 3 films.
3. Gathers keywords associated with each movie to present a comprehensive view of each film's characteristics.
4. Combines these elements into a final result set sorted by year and the number of appearances of the actors.
