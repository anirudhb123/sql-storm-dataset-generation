WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
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
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        all_actors,
        all_keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    all_actors,
    all_keywords
FROM 
    TopMovies
WHERE
    movie_rank <= 10
ORDER BY 
    cast_count DESC;

This query performs the following steps:
1. It creates a Common Table Expression (CTE) `RankedMovies` that aggregates information about movies, counting the unique cast members and concatenating their names and associated keywords.
2. It then creates another CTE `TopMovies` that ranks these movies based on their cast counts.
3. Finally, it selects the top 10 movies with the most cast members along with their titles, production years, actors, and keywords, ordered by the number of cast members.
