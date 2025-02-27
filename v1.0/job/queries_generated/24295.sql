WITH movie_revenue AS (
    SELECT 
        mt.movie_id,
        SUM(mo.revenue) AS total_revenue
    FROM 
        movie_info mo
    INNER JOIN 
        aka_title mt ON mo.movie_id = mt.movie_id
    WHERE 
        mo.info_type_id = (SELECT id FROM info_type WHERE info = 'revenue')
    GROUP BY 
        mt.movie_id
),
actor_filmography AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ai.movie_id) AS movies_count,
        STRING_AGG(DISTINCT at.title, ', ') AS titles
    FROM 
        cast_info ai
    JOIN 
        aka_title at ON ai.movie_id = at.movie_id
    WHERE 
        ai.note IS NULL
    GROUP BY 
        ai.person_id
),
high_revenue_movies AS (
    SELECT 
        mt.id,
        mt.title,
        mr.total_revenue
    FROM 
        aka_title mt
    JOIN 
        movie_revenue mr ON mt.movie_id = mr.movie_id
    WHERE 
        mr.total_revenue > (
            SELECT 
                AVG(total_revenue) FROM movie_revenue
        )
)

SELECT 
    nam.name AS actor_name,
    COUNT(DISTINCT aa.movie_id) AS movie_count,
    COALESCE(SUM(mr.total_revenue), 0) AS total_actor_revenue,
    RANK() OVER (PARTITION BY aa.person_id ORDER BY COALESCE(SUM(mr.total_revenue), 0) DESC) AS revenue_rank,
    ARRAY_AGG(DISTINCT h.title) FILTER (WHERE h.title IS NOT NULL) AS high_revenue_movie_titles
FROM 
    aka_name nam
INNER JOIN 
    cast_info aa ON nam.person_id = aa.person_id
LEFT JOIN 
    high_revenue_movies h ON aa.movie_id = h.id
LEFT JOIN 
    movie_revenue mr ON aa.movie_id = mr.movie_id
WHERE 
    nam.name IS NOT NULL
    AND nam.name != 'Anonymous'
GROUP BY 
    nam.name, aa.person_id
HAVING 
    COUNT(DISTINCT aa.movie_id) >= 5
    AND COUNT(DISTINCT aa.movie_id) < (
        SELECT 
            COUNT(DISTINCT ai.movie_id) 
        FROM 
            cast_info ai
        GROUP BY 
            ai.person_id
        ORDER BY 
            COUNT(DISTINCT ai.movie_id) DESC 
        LIMIT 1 OFFSET 10
    )
ORDER BY 
    revenue_rank, movie_count DESC
OFFSET 0 ROWS 
FETCH NEXT 20 ROWS ONLY;

### Explanation of the Query Constructs:
1. **Common Table Expressions (CTEs)**: 
   - `movie_revenue` aggregates revenue per movie.
   - `actor_filmography` counts unique movies per actor and aggregates their titles.
   - `high_revenue_movies` filters out movies above average revenue.
   
2. **Inner and Left Joins**: 
   - Joins `aka_name` with `cast_info`, and then joins with `high_revenue_movies` to bring in movie titles and revenue as needed.

3. **Subquery**: 
   - Used to calculate average total revenue and fetch actors with specific movie counts using HAVING clause.

4. **Aggregations**: 
   - `COUNT`, `SUM`, `STRING_AGG`, and `ARRAY_AGG` to summarize data, including collecting high-revenue movie titles.

5. **Window Functions**: 
   - `RANK()` is used to rank actors based on their revenue contributions.

6. **HAVING Clause**: 
   - Applies conditions on the aggregated results, ensuring that actors have a specific movie count and revenue statistics.

7. **Filtering and Order**: 
   - Conditions filter out actors with 'Anonymous' names and fetches the top 20 based on specified order criteria.

This query tests the system's capability to handle complex aggregation, filtering, and analytical requirements while probing deep into performance aspects with a wide array of SQL features.
