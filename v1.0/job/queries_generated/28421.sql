WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aliases,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aliases,
    ci.role_id,
    ci.note AS role_note,
    p.info AS person_info
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    person_info p ON p.person_id = ak.person_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;
This query does the following:
1. It first creates a Common Table Expression (CTE) `RankedMovies` that aggregates movie information, including aliases and the number of cast members for each movie.
2. In the second CTE `TopMovies`, it ranks these movies based on the number of cast members (in descending order).
3. Finally, it selects the top 10 movies from `TopMovies`, joining with `cast_info`, `aka_name`, and `person_info` to display detailed information about the roles, notes, and personal info of cast members related to those movies.
