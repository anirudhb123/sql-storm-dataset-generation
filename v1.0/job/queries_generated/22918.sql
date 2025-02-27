WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.title IS NOT NULL
),
FilteredTitles AS (
    SELECT
        aka_id,
        aka_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        year_rank <= 5 AND production_year >= 2000
),
TitleKeywordCounts AS (
    SELECT 
        f.aka_id,
        f.aka_name,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        FilteredTitles f
    LEFT JOIN 
        movie_keyword mk ON f.movie_id = mk.movie_id
    GROUP BY 
        f.aka_id, f.aka_name
),
FinalResults AS (
    SELECT 
        t.aka_name,
        COALESCE(t.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN t.keyword_count = 0 THEN 'No Keywords'
            WHEN t.keyword_count BETWEEN 1 AND 3 THEN 'Few Keywords'
            ELSE 'Many Keywords'
        END AS keyword_category
    FROM 
        TitleKeywordCounts t
    WHERE 
        t.aka_name IS NOT NULL OR t.aka_name IS NOT NULL
)
SELECT 
    f.aka_name,
    f.keyword_count,
    f.keyword_category,
    CASE 
        WHEN f.keyword_category = 'No Keywords' THEN NULL
        ELSE CONCAT(f.aka_name, ' has ', f.keyword_category)
    END AS review_statement
FROM 
    FinalResults f
WHERE 
    f.keyword_count > 0 OR f.keyword_category = 'No Keywords'
ORDER BY 
    f.keyword_count DESC NULLS LAST, 
    f.aka_name ASC;

-- This SQL query achieves several benchmarking aspects:
-- 1. Use of Common Table Expressions (CTEs) to break down the data processing steps.
-- 2. Implementing a window function to rank movies for each actor.
-- 3. Utilizing LEFT JOIN to include zero-keyword titles efficiently.
-- 4. Conditional aggregation to get keyword counts.
-- 5. String concatenation and NULL logic in case statements.
-- 6. Various predicates to filter and categorize the results.
