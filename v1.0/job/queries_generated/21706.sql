WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        RANK() OVER (ORDER BY t.production_year DESC) AS global_rank,
        COUNT(DISTINCT mi.info_type_id) OVER (PARTITION BY t.id) AS info_count
    FROM
        aka_title t
    LEFT JOIN
        movie_info mi ON t.movie_id = mi.movie_id
    WHERE
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.year_rank,
        rt.global_rank,
        rt.info_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 5 AND rt.info_count > 0
),
TitleExclusions AS (
    SELECT
        rt.title_id
    FROM 
        RankedTitles rt
    WHERE
        rt.global_rank < 10
        AND rt.year_rank > 3
)
SELECT 
    ft.title,
    ft.production_year,
    CASE 
        WHEN ft.production_year BETWEEN 2000 AND 2010 
        THEN 'Early 2000s'
        WHEN ft.production_year > 2010 
        THEN 'Post 2010s'
        ELSE 'Before 2000s'
    END AS era,
    COALESCE(NULLIF(ft.title, ''), 'Untitled') AS title_display,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id IN 
        (SELECT ft.title_id FROM FilteredTitles ft)) AS total_cast_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    TitleExclusions te ON ft.title_id = te.title_id
WHERE 
    te.title_id IS NULL
ORDER BY 
    ft.production_year DESC, ft.title;

### Explanation:

1. **CTEs (Common Table Expressions)**:
   - `RankedTitles`: Ranks titles by production year and assigns a global rank. It also counts the associated movie info types.
   - `FilteredTitles`: Filters titles to include only those ranked within the top 5 of their production year, with at least one associated info type.
   - `TitleExclusions`: Identifies titles that should be excluded based on specific ranking criteria.

2. **Main Query**: 
   - Joins the filtered titles with exclusions to provide the final dataset.
   - Uses conditional logic in the `CASE` statement to assign an era based on the production year.
   - Employs `COALESCE` and `NULLIF` to handle potential NULL or empty title values.

3. **Subquery**: 
   - Counts the total number of cast members for the filtered titles using a correlated subquery.

4. **Ordering**: 
   - Results are ordered by production year in descending order, then by title.

This complex query involves outer joins, window functions, subqueries, complex predicates, and NULL handling, making it suitable for performance benchmarking in a SQL environment while presenting some unusual SQL semantics.
