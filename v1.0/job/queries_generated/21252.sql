WITH RECURSIVE cte_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
cte_top_movies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        cte_movies
    WHERE 
        year_rank <= 5
    ORDER BY 
        production_year DESC
),
cte_cast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
cte_keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cte_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN m.production_year < 2000 THEN 'Oldie'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Classic'
            ELSE 'Recent'
        END AS movie_age_category
    FROM 
        aka_title m
    LEFT JOIN 
        cte_keyword_stats mk ON m.id = mk.movie_id
),

-- Final selection bringing everything together
final_query AS (
    SELECT 
        cte.title,
        cte.production_year,
        cte.movie_age_category,
        c.actor_name,
        COALESCE(cte.keyword_count, 0) AS keyword_count
    FROM 
        cte_top_movies cte
    LEFT JOIN 
        cte_cast c ON cte.movie_id = c.movie_id AND c.actor_rank <= 3
    ORDER BY 
        cte.production_year DESC, cte.title
)

SELECT 
    f.*,
    CASE 
        WHEN f.keyword_count IS NULL THEN 'No Keywords'
        WHEN f.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    final_query f
WHERE 
    (f.keyword_count > 0 OR f.actor_name IS NOT NULL)
ORDER BY 
    f.production_year DESC, f.title;

This SQL query incorporates various complex constructs:

1. **Common Table Expressions (CTEs)**: Used to generate intermediate datasets such as movies from different years and to rank actors.
2. **Window Functions**: Used to rank movies per year and actors per movie.
3. **Outer Joins**: Joining movie data to keyword stats and actor names.
4. **Correlated Subqueries**: Correlated statistics are used to gather keyword counts.
5. **Case Statements**: Used for categorizing movies based on their production year and popularity based on keyword counts.
6. **Complicated Predicates**: The use of `COALESCE` to handle potential NULL values in keyword counts.
7. **String Expressions**: To categorize the movie by age and judging popularity based on keyword counts.
8. **NULL Logic**: Handling cases where there are no associated keywords or actors.

Overall, the query is structured to provide insights into the top movies, their actors, and their popularity based on keywords.
