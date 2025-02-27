WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mk.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        movie_hierarchy mh ON mk.movie_id = mh.movie_id
    WHERE 
        mk.linked_movie_id IS NOT NULL
),
ranked_movies AS (
    SELECT 
        mt.title,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(mh.movie_id) OVER (PARTITION BY m.production_year) AS hierarchy_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_hierarchy mh ON mh.movie_id = m.id
    WHERE 
        m.production_year >= 2000
        AND (m.id % 2 = 0 OR m.title LIKE '%A%')  -- Arbitrary condition combing modulo and LIKE
),
string_agg_movies AS (
    SELECT 
        production_year,
        STRING_AGG(title, ', ') AS all_titles
    FROM 
        ranked_movies
    GROUP BY 
        production_year
)
SELECT 
    r.production_year,
    r.all_titles,
    COALESCE(CAST(NULLIF(SUM(CASE 
        WHEN r.company_type ILIKE 'Production%' THEN 1 
        ELSE 0 END), 0) AS INTEGER), 0) AS production_count,
    COUNT(DISTINCT r.title_rank) AS unique_title_count,
    MAX(hierarchy_count) AS max_hierarchy_depth
FROM 
    string_agg_movies r
LEFT JOIN 
    ranked_movies rm ON rm.production_year = r.production_year
LEFT JOIN 
    movie_hierarchy h ON h.movie_id = rm.movie_id
GROUP BY 
    r.production_year
ORDER BY 
    r.production_year DESC;

### Explanation of the Query:

1. **CTE `movie_hierarchy`:** This recursive CTE constructs a hierarchical representation of movies based on linked movies. It starts with movies that have a defined production year and recursively joins on the `movie_link` table to find linked movies.

2. **CTE `ranked_movies`:** This collects relevant information from the `aka_title`, `movie_companies`, and the previously defined hierarchy. It computes a rank based on the movie title within each production year and counts how many movies are in each hierarchy level.

3. **CTE `string_agg_movies`:** This aggregates titles grouped by production year into a single concatenated string.

4. **Final SELECT Statement:** This consolidates the aggregated data, calculating counts and maximum hierarchy depth while applying conditional logic:
   - The total number of "production" type counts is calculated (ignoring NULLs).
   - It uses `NULLIF` and `COALESCE` to gracefully handle cases where there may be zero production companies.
   - Finally, results are ordered by production year in descending order.

This query showcases varied SQL concepts including recursive CTEs, window functions, outer joins, conditional aggregation, and string aggregation, combined with some complex predicate logic.
