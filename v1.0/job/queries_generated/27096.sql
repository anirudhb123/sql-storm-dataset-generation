WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_names,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_names,
    m.keyword_count
FROM 
    FilteredRankedMovies m
WHERE 
    m.rank <= 5
ORDER BY 
    m.production_year DESC, m.keyword_count DESC;

This query benchmarks string processing by creating a Common Table Expression (CTE) to rank movies based on the number of distinct keywords associated with them, grouping by the production year. It joins multiple tables (aka_title, cast_info, aka_name, movie_keyword, and keyword) to gather necessary data about movies and actors. The final result filters for the top 5 movies per year with the most keywords, sorted by production year and keyword count.
