WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        tn.name AS main_actor,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name tn ON ci.person_id = tn.person_id
    WHERE 
        tn.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, tn.name
), 
HighRatedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
), 
MovieDetails AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        HighRatedMovies h
    LEFT JOIN 
        movie_companies mc ON h.movie_id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        h.movie_id, h.title, h.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.company_types
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;

This SQL query benchmarks string processing by performing various operations across multiple tables to extract and rank movie titles based on the count of main actors while gathering associated companies and company types. It filters to only the top main actor counts per year and provides aggregated data on the companies involved in those movies, showcasing complex joins, aggregates, and string functions like `STRING_AGG`, making it suitable for performance benchmarking in a database environment.
