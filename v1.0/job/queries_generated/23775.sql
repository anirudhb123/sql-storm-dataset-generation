WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating') 
        AND t.production_year IS NOT NULL
),
GoldenYears AS (
    SELECT 
        production_year, 
        AVG(m.rating) AS avg_rating 
    FROM 
        RankedMovies m
    WHERE 
        m.rank_per_year <= 3 
    GROUP BY 
        production_year
    HAVING 
        COUNT(m.movie_id) >= 5
),
TopMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        g.avg_rating
    FROM 
        RankedMovies r
    JOIN 
        GoldenYears g ON r.production_year = g.production_year
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.id) AS total_movies,
    COALESCE(SUM(m.note IS NOT NULL AND m.note LIKE '%best%'), 0) AS best_movies_count,
    STRING_AGG(DISTINCT t.title, ', ' ORDER BY t.title) AS titles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    TopMovies m ON c.movie_id = m.movie_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND a.name <> ''
    AND EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year <= 25 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    total_movies DESC 
LIMIT 10;

### Query Breakdown:

1. **CTEs (Common Table Expressions):**
   - `RankedMovies`: This CTE ranks movies per production year based on their titles.
   - `GoldenYears`: This CTE filters for years where there are a sufficient number of high-ranked movies and calculates average ratings, ensuring no year with fewer than 5 rated movies is included.
   - `TopMovies`: This picks the top movies from the `RankedMovies` that also appear in `GoldenYears`.

2. **Joins:**
   - The main query joins the `aka_name` table to `cast_info` to associate actors with their movies, and then further joins to `TopMovies` and `aka_title` for movie metadata.

3. **Aggregate Functions:**
   - Counts the total distinct movies each actor was involved in.
   - Counts instances of movies marked with keywords in their notes, using a conditional aggregate to sum occurrences of the term "best."
   - Combines movie titles into a single string.

4. **Filters and Logic:**
   - Uses a COALESCE to handle NULLs.
   - The HAVING clause ensures only actors with more than one movie are included.
   - The EXTRACT function is used to filter by production year in relation to the current date.

This query blends various SQL entities and constructs to create a complex, multi-faceted query, suitable for performance benchmarking and advanced SQL exercise.
