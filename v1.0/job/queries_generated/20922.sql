WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS title,
        mt.production_year,
        mt.kind_id,
        NULL::integer AS parent_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        mc.linked_movie_id AS movie_id,
        l.title AS title,
        l.production_year,
        l.kind_id,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        movie_link mc
    JOIN title l ON mc.linked_movie_id = l.id
    JOIN movie_hierarchy mh ON mc.movie_id = mh.movie_id
)

SELECT
    m.title,
    m.production_year,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'Modern'
    END AS era,
    ARRAY_AGG(DISTINCT a.name) AS actors,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COUNT(CASE WHEN c.kind_id IS NOT NULL THEN 1 END) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num,
    AVG(COALESCE(mi.info::numeric, 0)) AS avg_info_value
FROM 
    movie_hierarchy m
LEFT JOIN cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_name c ON mc.company_id = c.id
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget' LIMIT 1)
WHERE 
    (m.production_year >= 1980 AND m.production_year < 2023) OR
    (m.production_year IS NULL AND m.kind_id IS NOT NULL)
GROUP BY
    m.movie_id, m.title, m.production_year, m.kind_id
HAVING
    COUNT(DISTINCT ci.person_id) > 1 AND
    COALESCE(SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE NULL END), 0) > 0
ORDER BY
    level, era, m.title;

### Explanation of Constructs:
1. **CTE (Common Table Expression)**: The `movie_hierarchy` CTE recursively builds a hierarchy of movies, linking `aka_title` and `movie_link` tables based on relationships.
2. **Aggregations**: Various aggregates such as `ARRAY_AGG` and `COUNT` are used to summarize actor names, keyword counts, and company count.
3. **Window Functions**: The `ROW_NUMBER()` function partitions by production year to provide a rank within each year.
4. **CASE Statements**: Used to categorize movies into 'Classic', 'Recent', and 'Modern' based on the production year.
5. **Complex Filtering**: The `WHERE` clause ensures that it captures specific years while taking into account NULL conditions.
6. **NULL Logic**: The query is built to handle NULL values gracefully using `COALESCE` and complex filtering.
7. **HAVING Clause**: To ensure only movies associated with multiple actors and having related information are included, demonstrating the conditions that must be met post-aggregation.
8. **Subqueries**: Inclusion of a subquery to fetch `info_type_id` for 'Budget' adds a layer of filtration based on dynamic criteria.

This query showcases a combination of performance benchmarking through exploratory data relationships while pushing the limits of SQL structure and logic.
