WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
filtered_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(ci.role_id) AS total_roles
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NULL OR ci.note LIKE '%lead%'
    GROUP BY 
        ci.movie_id, ci.person_id
),
movie_details AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(mk.keyword_id), 0) AS total_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
final_results AS (
    SELECT 
        rt.production_year,
        rt.title,
        rt.year_rank,
        fc.total_roles,
        md.total_keywords,
        COALESCE(fc.total_roles, 0) * COALESCE(md.total_keywords, 1) AS interaction_score
    FROM 
        ranked_titles rt
    LEFT JOIN 
        filtered_cast fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        movie_details md ON rt.title_id = md.movie_id
    WHERE 
        rt.year_rank <= 5
        AND (md.total_keywords IS NULL OR md.total_keywords >= 3)
)

SELECT 
    production_year,
    title,
    year_rank,
    total_roles,
    total_keywords,
    interaction_score,
    CASE 
        WHEN interaction_score < 10 THEN 'Low Interaction'
        WHEN interaction_score BETWEEN 10 AND 30 THEN 'Medium Interaction'
        ELSE 'High Interaction'
    END AS interaction_category
FROM 
    final_results
WHERE 
    (total_roles IS NULL OR total_roles > 0)
ORDER BY 
    production_year DESC, interaction_score DESC
LIMIT 50;

### Explanation:

1. **CTEs (Common Table Expressions)**:
   - `ranked_titles`: Ranks titles by year and counts the number of titles produced in each year, excluding NULL production years.
   - `filtered_cast`: Aggregates roles in `cast_info` where the note is NULL or contains "lead”, grouping by `movie_id` and `person_id`.
   - `movie_details`: Summarizes movie keywords associated with each title with a LEFT JOIN on `movie_keyword`.

2. **Combining the Data**:
   - The `final_results` CTE combines the previous CTEs to glean insights on the top-ranked titles, roles in the cast, and keyword counts, calculating an `interaction_score` as a product of total roles and total keywords.

3. **Final Selection**:
   - The main query filters these results to return only those movies with a ranked position of 5 or less, with at least some roles or no NULL roles and keywords of at least 3, while also categorizing interaction based on the score.

4. **ORDER BY & LIMIT**:
   - The results are ordered by the production year (descending) and interaction score (descending), providing a quantitative insight into the most actively engaged titles, limited to the top 50 results.

This complex SQL query illustrates multiple advanced concepts like window functions, CTEs, outer joins, and advanced filtering logic, yielding insightful outcomes while adhering to the schema provided.
