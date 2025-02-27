WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        title.kind_id,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        aka_name.person_id,
        aka_name.name AS actor_name,
        aka_title.id AS title_id,
        aka_title.title,
        aka_title.production_year
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        aka_title ON cast_info.movie_id = aka_title.movie_id
    WHERE 
        aka_name.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
movies_with_cast AS (
    SELECT 
        am.actor_name,
        am.title,
        am.production_year,
        rk.year_rank,
        mk.keywords
    FROM 
        actor_movies am 
    JOIN 
        ranked_titles rk ON am.title_id = rk.title_id
    LEFT JOIN 
        movie_keywords mk ON am.title_id = mk.movie_id
),
final_output AS (
    SELECT 
        actor_name,
        title,
        production_year,
        year_rank,
        COALESCE(keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN year_rank = 1 THEN 'First Ranked of Year'
            WHEN year_rank > 1 AND year_rank <= 3 THEN 'Top 3'
            ELSE 'Other'
        END AS rank_category
    FROM 
        movies_with_cast
)
SELECT 
    actor_name,
    title,
    production_year,
    rank_category,
    COUNT(*) OVER (PARTITION BY rank_category) AS count_per_category,
    DENSE_RANK() OVER (ORDER BY production_year DESC, title ASC) AS movie_rank
FROM 
    final_output
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    rank_category, 
    actor_name;

This SQL query performs the following tasks:

1. **Common Table Expressions (CTEs)**: Utilizes multiple CTEs to structure the query logically.
2. **Window Functions**: Includes `ROW_NUMBER` to rank titles by production year, and `DENSE_RANK` to rank movies overall, with aggregation functions.
3. **String Aggregation**: Uses `STRING_AGG` to concatenate keywords related to movies.
4. **NULL Logic**: Employs `COALESCE` to ensure non-null output for keywords.
5. **Bizarre Semantics**: Implements predicates like categorizing ranks based on specific conditions.
6. **Outer Joins**: Performs a LEFT JOIN to include movies with and without keywords.
7. **Complex Filtering**: Specifies a production year range to filter results.

This query benchmark performance by joining multiple large tables, and the inclusion of ranking and aggregation introduces intricate computation, demonstrating database efficiency under complex conditions.
