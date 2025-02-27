WITH RecursiveMovieRanks AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
MovieRatings AS (
    SELECT 
        m.movie_id,
        AVG(COALESCE(m_info.info::FLOAT, 0)) AS average_rating
    FROM 
        movie_info m_info
    JOIN 
        title m ON m.movie_id = m_info.movie_id
    WHERE 
        m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        m.movie_id,
        t.title,
        r.average_rating,
        RANK() OVER (ORDER BY r.average_rating DESC) AS rating_rank
    FROM
        title t
    JOIN 
        MovieRatings r ON t.id = r.movie_id
)
SELECT 
    tm.title,
    ARRAY_AGG(DISTINCT r.actor_name) AS cast_members,
    tm.average_rating,
    COALESCE(COUNT(DISTINCT mc.id), 0) AS company_count,
    STRING_AGG(DISTINCT co.name, ', ') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    RecursiveMovieRanks r ON tm.movie_id = r.movie_id
WHERE 
    tm.rating_rank <= 10
GROUP BY 
    tm.title, tm.average_rating
ORDER BY 
    tm.average_rating DESC;

**Explanation:**

1. **RecursiveMovieRanks CTE**: This CTE retrieves the ranks of cast members for each movie ordered by their appearance in the cast list (`nr_order`). It uses `RANK()` to assign ranks to each actor.

2. **MovieRatings CTE**: This CTE calculates the average rating for each movie. The `COALESCE` function ensures that if a movie does not have a rating, it treats it as 0.

3. **TopMovies CTE**: This combines the title information with the average ratings computed in the previous CTE. It assigns ranking to the movies based on their average ratings.

4. **Final SELECT Statement**: This part gathers details from `TopMovies`, including the movie's title, the cast members as an array, the average rating, the count of companies associated with the movie, and lists the company names associated with each movie. The use of aggregation functions (`ARRAY_AGG`, `STRING_AGG`) is prominent, and `LEFT JOIN` ensures that even movies with no cast or companies are included. The `WHERE` clause limits results to the top 10 rated movies.

The query combines various SQL constructs such as CTEs, window functions, GROUP BY with aggregation, outer joins, and even uses clever NULL handling to ensure complete coverage of data.
