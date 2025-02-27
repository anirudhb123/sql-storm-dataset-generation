WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
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
MovieRanked AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        keywords,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    m.actor_names,
    m.keywords
FROM 
    MovieRanked m
WHERE 
    m.rank <= 5
ORDER BY 
    m.production_year DESC, m.actor_count DESC;

This query provides a benchmarking approach to string processing by aggregating movie data with associated actors and keywords while utilizing Common Table Expressions (CTEs) for clarity and efficiency. It ranks the top 5 movies per production year based on the number of unique actors, allowing for performance evaluation of text and string manipulations within the database.
