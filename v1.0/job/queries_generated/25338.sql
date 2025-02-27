WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(*) AS actor_count
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(*) > 5 -- Only movies with more than 5 actors
),
TopMovies AS (
    SELECT 
        rm.*,
        RANK() OVER (ORDER BY rm.actor_count DESC) AS rank
    FROM 
        RankedMovies rm
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        tm.rank <= 10 -- Top 10 movies by actor count
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;

This query does the following:
1. **Ranks Movies** by counting the number of actors for each movie, selecting only those with more than 5 actors.
2. **Selects the Top 10 Movies** from the ranked list based on the actor count.
3. **Collects Actor Names and Keywords** for each of the top movies, ensuring no duplicates with `STRING_AGG`.
4. **Outputs** the movie details, ordered by production year in descending order.
