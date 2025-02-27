WITH RECURSIVE json_agg_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, '<unknown>') AS production_year,
        COALESCE(ca.name, 'Unknown Actor') AS actor,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword), 'No Keywords') AS keywords,
        COUNT(mci.*) OVER (PARTITION BY m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ca.name) AS actor_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.movie_id
    LEFT JOIN 
        aka_name ca ON ca.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL 
    GROUP BY 
        m.id, ca.name
    HAVING 
        COUNT(mci.*) > 1 -- Only movies with more than 1 company
),
aggregated_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor, ', ') AS actors,
        keywords,
        MAX(company_count) AS company_count
    FROM 
        json_agg_movies
    GROUP BY 
        movie_id, title, production_year, keywords
)
SELECT 
    title,
    production_year,
    actors,
    keywords,
    company_count,
    CASE 
        WHEN company_count > 3 THEN 'Blockbuster'
        WHEN company_count BETWEEN 2 AND 3 THEN 'Moderate Budget'
        ELSE 'Indie Film'
    END AS film_category,
    COALESCE(NULLIF(SUBSTRING(title FROM '[A-Z0-9]'), ''), 'Untitled Film') AS film_code,
    ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
FROM 
    aggregated_movies
WHERE 
    EXISTS (
        SELECT 
            1
        FROM 
            name n
        WHERE 
            n.imdb_id IS NOT NULL
        AND
            n.name LIKE '%the%'
    )
ORDER BY 
    production_year DESC, 
    title ASC
LIMIT 100 OFFSET 0;

### Explanation
1. **Common Table Expressions (CTEs)**: This query uses two CTEs. The first `json_agg_movies` aggregates data for movies, their actors, and keywords, while ensuring that only movies with more than one company are included. The second CTE, `aggregated_movies`, further aggregates the results to consolidate different aspects of the movies.

2. **Complex Joins**: The query includes multiple left joins, facilitating a rich dataset by merging various tables. 

3. **Subqueries**: The main query uses an `EXISTS` clause to filter results based on a condition involving another table.

4. **Window Functions**: `ROW_NUMBER()` is used to rank movies by production year and actor order.

5. **String Expressions**: The incorporation of `STRING_AGG()` allows for concatenation of actor names.

6. **NULL Logic**: The query utilizes `COALESCE` and `NULLIF` to handle missing data gracefully.

7. **Predicates**: The `HAVING` clause filters out results that don’t meet the conditions regarding companies.

8. **Bizarre Semantics**: The expression that generates a `film_code` from `title` demonstrates the use of regex-like patterns and a fallback for missing values.

This query aims for performance benchmarking, ensuring that various SQL constructs are tested under load while we analyze movies with complex relationships and attributes.
