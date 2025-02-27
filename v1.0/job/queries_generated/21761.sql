WITH RecursiveTitleCTE AS (
    SELECT t.id, t.title, t.production_year, t.kind_id,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
), RoleStats AS (
    SELECT ci.movie_id, rt.role AS role, COUNT(ci.person_id) AS num_roles
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
), MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ' ORDER BY kt.keyword) AS genres
    FROM movie_keyword mk
    JOIN keyword kt ON mk.keyword_id = kt.id
    GROUP BY mt.movie_id
), NullHandling AS (
    SELECT 
        m.id AS movie_id,
        tn.title,
        tn.production_year,
        COALESCE(rs.num_roles, 0) AS total_roles,
        COALESCE(mg.genres, 'No Genre') AS genres
    FROM title tn
    LEFT JOIN RoleStats rs ON tn.id = rs.movie_id
    LEFT JOIN MovieGenres mg ON tn.id = mg.movie_id
), GenreCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT genres) AS genre_count
    FROM nullHandling
    GROUP BY movie_id
)
SELECT 
    n.id AS person_id,
    ak.name AS actor_name,
    nt.title AS movie_title,
    nt.production_year,
    nc.genre_count,
    nt.total_roles
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN nullHandling nt ON ci.movie_id = nt.movie_id
LEFT JOIN GenreCount nc ON nt.movie_id = nc.movie_id
WHERE nt.production_year > (
    SELECT AVG(production_year) 
    FROM title
) OR ak.name IS NULL
ORDER BY 
    nt.production_year DESC,
    actor_name,
    genre_count DESC
FETCH FIRST 10 ROWS ONLY;

This query combines multiple advanced SQL features. Here’s a breakdown of its components:

1. **Common Table Expressions (CTEs)**:
   - `RecursiveTitleCTE`: Identifies movie titles while ranking them by production year.
   - `RoleStats`: Counts the number of roles per movie.
   - `MovieGenres`: Aggregates keywords to form a list of genres for movies.
   - `NullHandling`: Merges data from titles, roles, and genres while handling potential nulls.
   - `GenreCount`: Counts unique genres for each movie.

2. **Outer Joins**: 
   - Used in the `NullHandling` CTE to combine movie, role, and genre data even where the data might not fully exist.

3. **Subquery**: 
   - A correlated subquery to filter out titles based on the average production year.

4. **COALESCE Function**: 
   - To handle cases where there might not be any roles or genres associated with a movie, replacing nulls with default values.

5. **String Aggregation**: 
   - `STRING_AGG` is used to concatenate multiple genres for each movie.

6. **Sorting and Limiting**: 
   - Final selection sorts results and limits output to the top 10.

The combination of these factors creates a complex yet comprehensive view of the data, suitable for performance benchmarking by evaluating the efficiency of this SQL structure against various indices.
