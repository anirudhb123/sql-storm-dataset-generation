WITH RECURSIVE movie_cast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order ASC) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id 
    WHERE 
        ak.name IS NOT NULL
),
complex_title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_names,
        (SELECT COUNT(*) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT m.id) > 2
)
SELECT 
    ct.title,
    ct.production_year,
    MAX(mb.actor_order) AS max_actor_order,
    COALESCE(ct.companies_names, 'No Companies') AS company_names,
    ct.keyword_count,
    CASE 
        WHEN ct.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS title_popularity
FROM 
    complex_title_info ct
LEFT JOIN 
    movie_cast mb ON ct.title_id = mb.movie_id
GROUP BY 
    ct.title, ct.production_year, ct.company_count, ct.keyword_count
ORDER BY 
    ct.production_year DESC, max_actor_order ASC
LIMIT 
    10;

This SQL query combines multiple features:

1. **Common Table Expressions (CTEs)**: 
   - `movie_cast` generates a ranking of actors per movie, allowing for flexible analysis based on actor roles.
   - `complex_title_info` aggregates production-related data while using `STRING_AGG` to concatenate company names.

2. **Window Functions**: The use of `ROW_NUMBER()` provides a sequential order of actors by movie, which can help us analyze ensemble casts.

3. **Outer Joins**: The `LEFT JOIN` statements ensure that we include all titles even if they may not have associated company data or actors.

4. **Complex Aggregations**: 
   - `COUNT(DISTINCT)` and `STRING_AGG` on various titles create rich summary records.
   - `HAVING` filters the result to return only titles produced with more than 2 companies.

5. **Correlated Subqueries**: The keyword count is determined with a subquery linked to the main movie.

6. **Conditional Logic**: The `CASE` constructs offer a classification of movies based on the number of keywords.

7. **NULL Handling**: `COALESCE` ensures that titles with no companies are represented clearly in the final result. 

8. **Complicated Predicates and Calculations**: Various filters based on date range, null checks, and contextual aggregations are applied. 

Overall, the query captures an elaborate cross-section of data from the schema while showcasing advanced SQL functionalities.
