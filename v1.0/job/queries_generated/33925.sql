WITH RECURSIVE popular_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN ci person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        info_type it ON cc.status_id = it.id
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
ranked_movies AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.actor_count,
        RANK() OVER (ORDER BY pm.actor_count DESC) AS actor_rank
    FROM 
        popular_movies pm
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.actor_rank,
    COALESCE(mk.keywords, 'No keywords available') AS movie_keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rm.movie_id) AS company_count
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.actor_rank <= 10 -- Top 10 movies by actor count
ORDER BY 
    rm.actor_count DESC;

### Explanation:
- The query works through a series of Common Table Expressions (CTEs):
  - The first CTE, `popular_movies`, aggregates data from `aka_title`, `cast_info`, and `complete_cast`, counting distinct actors and the number of roles for each movie, filtering for movies with more than 5 actors.
  - The second CTE, `ranked_movies`, ranks those movies based on the number of actors.
  - The third CTE, `movie_keywords`, aggregates the associated keywords for each movie.
- The final `SELECT` statement retrieves the top 10 ranked movies, their actor count, and the aggregated keywords, while also counting associated companies.
- The query uses outer joins, window functions, subqueries, string aggregations, filtering, grouping, and NULL logic.
