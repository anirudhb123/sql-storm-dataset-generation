WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(AVG(r.rating), 0) AS avg_rating,
        COUNT(r.id) AS rating_count
    FROM 
        aka_title m
        LEFT JOIN ratings r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type ct ON mc.company_type_id = ct.id
),
cast_details AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank,
        COUNT(c.id) FILTER (WHERE c.person_role_id IS NOT NULL) AS total_roles
    FROM 
        cast_info c
        JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id, ak.name
),
top_movies AS (
    SELECT 
        m.id,
        m.title,
        mr.avg_rating,
        mr.rating_count,
        ROW_NUMBER() OVER (ORDER BY mr.avg_rating DESC) AS movie_rank
    FROM 
        aka_title m
        JOIN movie_ratings mr ON m.id = mr.movie_id
    WHERE 
        mr.rating_count >= 5
)
SELECT 
    tm.title AS top_movie_title,
    cd.company_name,
    cd.company_type,
    cd.company_rank,
    ca.actor_name,
    ca.actor_rank,
    ca.total_roles
FROM 
    top_movies tm
LEFT JOIN 
    company_details cd ON tm.id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN 
    cast_details ca ON tm.id = ca.movie_id AND ca.actor_rank = 1
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.avg_rating DESC, cd.company_name ASC, ca.actor_name ASC;

### Explanation:
1. **CTEs**: 
   - `movie_ratings`: This calculates the average rating and count of ratings for each movie using an outer join with a ratings table (which is not part of provided schema but implied).
   - `company_details`: Extracts company names and types with rankings based on the movie.
   - `cast_details`: Aggregates actor names and counts the total roles for each movie with rankings.

2. **Main Selection**: 
   - Joins top-rated movies with their primary company and lead actor information.

3. **Filters**: 
   - Restricts to movies with at least 5 ratings, allowing the analysis of the top 10 rated movies.

4. **Sorting**: 
   - Orders results by average rating and further by company name and actor name for an easy top-view.

5. **NULL Handling**: 
   - Utilizes `COALESCE` in the ratings calculation to handle cases where there might be no ratings.

This SQL statement integrates complex constructs like CTEs, window functions, correlated calculations, and various outer joins to elegantly generate a report on the top-rated movies along with their associated companies and actors. The choice of logic and structure demonstrates a nuanced approach to working with potentially large datasets while providing valuable insights.
