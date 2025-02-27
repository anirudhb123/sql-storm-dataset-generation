WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast, 
        actors, 
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actors,
    t.kind AS movie_type
FROM 
    TopMovies tm
JOIN 
    title t ON tm.movie_id = t.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;

This query does the following:
1. It creates a Common Table Expression (CTE) named `RankedMovies` that aggregates movies produced after 2000, counting the total distinct cast members and aggregating actor names and keywords into strings.
2. It then creates another CTE named `TopMovies` that ranks these movies by the number of cast members.
3. Finally, it selects the top 10 movies, including their rank, title, production year, total cast members, actors' names, and the type of movie.
