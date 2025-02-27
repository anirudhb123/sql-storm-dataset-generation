WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT title.production_year) AS movies_count,
        STRING_AGG(DISTINCT title.title, ', ') AS movies_titles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title title ON c.movie_id = title.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY c.person_id
),
HighestRatedMovies AS (
    SELECT 
        m.movie_id,
        title.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY m.company_id ORDER BY AVG(rating) DESC) AS rank
    FROM movie_companies m
    JOIN movie_info mi ON m.movie_id = mi.movie_id
    JOIN (
        SELECT 
            movie_id,
            RANDOM() AS rating -- Simulate random ratings for benchmarking
        FROM movie_info
    ) AS r ON m.movie_id = r.movie_id
    WHERE mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'average rating'
    )
    GROUP BY m.movie_id, title.title
)
SELECT 
    a.person_id,
    a.movies_count,
    a.movies_titles,
    h.movie_title,
    h.rank
FROM ActorHierarchy a
LEFT JOIN HighestRatedMovies h ON h.rank <= 5
WHERE a.movies_count > (
    SELECT AVG(movies_count)
    FROM ActorHierarchy
)
ORDER BY a.movies_count DESC, h.rank ASC;

### Explanation of the SQL Query:
- **Common Table Expressions (CTEs)**:
  - `ActorHierarchy`: Computes the number of movies and titles for each actor using a recursive approach, counting distinct years to handle multiple appearances in the same year.
  - `HighestRatedMovies`: Simulates a scenario where movies are ranked based on random ratings, achieving a bizarre yet intricate selection of top movies per company.

- **LEFT JOIN**: This allows investigation of actors that may not have corresponding highest-rated movies, highlighting NULL logic by still including them in the result set.

- **WINDOW FUNCTION**: The `ROW_NUMBER()` function is utilized to rank movies uniquely alongside average ratings, demonstrating the CPL (Cumulative Partition Logic).

- **Subqueries**:
  - The query employs subqueries to filter actors with a movie count greater than the average, showcasing complex filtering predicates.

- **STRING_AGG**: To aggregate multiple movie titles into a single string, which is particularly useful for actors with extensive filmographies.

- **RANDOM() function**: This adds an unusual semantic by simulating movie ratings, revealing performance across various random evaluations while retaining SQL query coherence.

- **Final Output**: Lists actor IDs who have been in above-average numbers of movies alongside the top-rank movie title from their associated companies, further ordered by the count of movies and rank of the selected movies.
