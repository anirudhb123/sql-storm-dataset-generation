WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) as movie_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keywords,
    p.name AS person_name,
    r.role AS movie_role
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.id = ci.movie_id
JOIN 
    name p ON ci.person_id = p.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year DESC;

### Explanation:

1. **RankedMovies** CTE:
   - This common table expression (CTE) consolidates movie details including title, production year, number of cast members, and a list of unique keywords associated with each movie.

2. **TopMovies** CTE:
   - From `RankedMovies`, it selects the top 10 movies sorted by the number of cast members, ranking them to facilitate a cutoff for the final selection.

3. **Final Selection**:
   - The final select statement retrieves the title, production year, cast count, keywords for movies that are in the top 10 by cast count. 
   - It joins with `cast_info` to get person IDs, and subsequently joins with `name` and `role_type` to append actor names associated with their respective roles in the movie.

4. **Ordering**:
   - The results are ordered primarily by `cast_count` in descending order, and then by `production_year` to see the most recent highest cast films first.

This query effectively benchmarks string processing by aggregating and concatenating keyword data while calculating counts and applying ranking.
