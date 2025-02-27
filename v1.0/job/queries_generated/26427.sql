WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS akas,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    t.movie_id,
    t.movie_title,
    t.production_year,
    t.total_cast,
    t.akas,
    t.keywords
FROM 
    TopMovies t
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_cast DESC;

This SQL query first aggregates movie titles along with their alternative names (akas) and keywords, ranking them based on the number of unique cast members. It retrieves the top 10 movies with the highest cast counts, providing insights into which movies feature the most diverse talent, and includes any alternate names and keywords associated with those films.
