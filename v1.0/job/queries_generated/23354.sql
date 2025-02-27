WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN role.kind IS NOT NULL THEN 'Yes' ELSE 'No' END) AS has_named_roles
    FROM 
        cast_info ci
    LEFT JOIN 
        comp_cast_type role ON ci.person_role_id = role.id
    GROUP BY 
        ci.movie_id
),
movie_with_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        coalesce(mk.keyword, 'No Keyword') AS keyword,
        mk.id AS keyword_id,
        ci.total_cast,
        ci.has_named_roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        cast_summary ci ON ci.movie_id = m.id
    WHERE 
        (m.production_year < 2000 OR m.production_year IS NULL)
)
SELECT 
    mt.title AS movie_title,
    mt.production_year,
    mt.keyword,
    count(DISTINCT mc.company_id) FILTER (WHERE mc.company_type_id = 1) AS production_companies, -- assuming company_type_id = 1 is for production
    AVG(m.info_length) AS avg_info_length,
    JSON_AGG(DISTINCT p.name) AS cast_names
FROM 
    movie_with_info mt
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.movie_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        LENGTH(mi.info) AS info_length
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
) m ON m.movie_id = mt.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mt.movie_id
LEFT JOIN 
    aka_name p ON p.person_id = ci.person_id
WHERE 
    mt.keyword_id IS NULL OR mt.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
GROUP BY 
    mt.title, mt.production_year, mt.keyword
HAVING 
    COUNT(DISTINCT mt.keyword_id) > 0 OR mt.keyword IS NOT NULL
ORDER BY 
    mt.production_year DESC, movie_title ASC
LIMIT 100;

### Explanation of the SQL Query:

1. **Common Table Expressions (CTEs)**:
   - `ranked_titles`: Ranks titles by year to facilitate comparisons across production years.
   - `cast_summary`: Provides a summary of cast members for each movie.
   - `movie_with_info`: Combines movie information with keywords and cast summaries, while also applying certain filters.

2. **Joins**:
   - Utilizes left joins to incorporate data from related tables (e.g., `movie_keyword`, `cast_info`, and `movie_companies`).

3. **Filtering**:
   - Applies complicated predicates in the WHERE clause to filter movies based on production years and keywords.

4. **Aggregation and Window Functions**:
   - Uses `COUNT`, `AVG`, and `JSON_AGG` to gather aggregated information.
   - The window function `ROW_NUMBER()` is used to rank titles.

5. **Handling NULL Values**: 
   - Utilizes the `COALESCE()` function to handle potential NULLs from left joins.

6. **Conditional Aggregation**:
   - The `FILTER` clause is employed within the `COUNT` function to count only certain types of companies.

7. **HAVING Clause**:
   - Implements complex conditions to filter the results after aggregation.

8. **Ordering and Limiting**:
   - Orders the result set by production year in descending order and movie title in ascending order, limiting output to the top 100 records. 

This query provides a comprehensive analysis of movies while incorporating various SQL concepts and complexity.
