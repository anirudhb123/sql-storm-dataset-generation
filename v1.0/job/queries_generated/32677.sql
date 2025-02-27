WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id, m.title, m.production_year, mh.level + 1 
    FROM aka_title m
    INNER JOIN movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT ka.name) AS actors,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    INNER JOIN aka_name ka ON ka.person_id = ci.person_id
    GROUP BY ci.movie_id
),
movie_details AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(c.actor_count, 0) AS actor_count,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN cast_stats c ON c.movie_id = m.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    WHERE m.production_year >= 2000
    GROUP BY m.id, m.title, m.production_year, c.actor_count
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS actor_rank,
        DENSE_RANK() OVER (ORDER BY md.production_year, md.actor_count DESC) AS overall_rank
    FROM 
        movie_details md
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_count,
    r.actor_rank,
    r.overall_rank,
    COALESCE(mh.level, 0) AS movie_level
FROM 
    ranked_movies r
LEFT JOIN movie_hierarchy mh ON r.movie_id = mh.movie_id
WHERE 
    r.actor_count > 5
ORDER BY 
    r.production_year DESC,
    r.actor_rank
LIMIT 10;

This SQL query performs the following functions:

1. **Recursive CTE (Common Table Expression)** - `movie_hierarchy` constructs a hierarchy of movies from the year 2000 onward by fetching linked movies. 

2. **Aggregation** - `cast_stats` gathers the unique actors and counts them per movie.

3. **NULL Logic** - The use of `COALESCE` ensures that movies without associated actors or companies do still return a count of zero.

4. **Window Functions** - It ranks the movies by actor counts and production year through `RANK()` and `DENSE_RANK()`.

5. **Outer Joins** - Utilizes LEFT JOIN to maintain movies even if they lack actor or company associations.

6. **Complex Filtering** - Filters out movies with fewer than six actors, ensuring only significant films are included.

7. **Final Selection** - Presents top movies based on the specified conditions, displaying titles, production years, actor counts, and ranks.

This sophisticated query facilitates performance benchmarking while demonstrating SQL's capabilities in handling complex relationships and aggregations.
