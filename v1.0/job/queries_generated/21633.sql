WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mci.note, 'No Note') AS company_note,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS prod_year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    LEFT JOIN 
        company_name mci ON mc.company_id = mci.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoleCTE AS (
    SELECT 
        ci.movie_id,
        ri.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        ci.movie_id, ri.role
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(COUNT(DISTINCT p.person_id), 0) AS unique_actors,
    MAX(CASE WHEN pr.role = 'lead' THEN pr.role_count ELSE 0 END) AS lead_actor_count,
    STRING_AGG(DISTINCT p.name, ', ') AS actor_names
FROM 
    RecursiveMovieCTE m
LEFT JOIN 
    KeywordCTE k ON m.movie_id = k.movie_id
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    PersonRoleCTE pr ON m.movie_id = pr.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, k.keywords
HAVING 
    COUNT(DISTINCT p.person_id) > 1 AND m.prod_year_rank <= 5
ORDER BY 
    m.production_year DESC, unique_actors DESC;

The above SQL query showcases a complex structure utilizing Common Table Expressions (CTEs) to organize data about movies, keywords, and cast information in a relational database.

Key features of this SQL query include:

1. **CTEs for Recursive Queries**: The `RecursiveMovieCTE` collects movie details alongside company notes while preserving movie production year ranks.

2. **Aggregating Keywords**: The `KeywordCTE` uses `STRING_AGG` to collate multiple keywords related to movies, allowing you to retrieve comprehensive keyword lists.

3. **Counting Distinct Roles**: In `PersonRoleCTE`, the query counts the occurrences of different roles per movie, aiding analysis of actor roles.

4. **Combining Data**: The main query combines all the previously defined CTEs using outer joins while leveraging conditional aggregation with `CASE` directly in the `SELECT` statement to derive insights on lead actor counts.

5. **Null Handling**: The `COALESCE` function ensures no NULL values disrupt results by providing meaningful fallback text and zero counts.

6. **Conditional Filtering**: The use of the `HAVING` clause ensures only movies with more than one unique actor and within the top 5 ranks of their production years are returned.

7. **Ordering the Results**: The final results are ordered by `production_year` and the unique actor count to present the most pertinent data first.

This query encapsulates various SQL constructs, providing a well-rounded and intricate benchmark suitable for performance evaluation.
