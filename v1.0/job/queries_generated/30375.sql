WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level,
        m.production_year,
        t.kind AS title_kind,
        NULL AS parent_id
    FROM title m
    INNER JOIN kind_type t ON m.kind_id = t.id

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        m.production_year,
        t.kind AS title_kind,
        mh.movie_id AS parent_id
    FROM title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN kind_type t ON m.kind_id = t.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.title_kind,
    COALESCE(aka.name, 'Unknown') AS aka_name,
    AVG(COALESCE(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order END, 0)) OVER (PARTITION BY mh.movie_id) AS avg_order,
    COUNT(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    CASE WHEN count(DISTINCT ml.linked_movie_id) > 0 THEN 'Yes' ELSE 'No' END AS has_links,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn
FROM MovieHierarchy mh
LEFT JOIN aka_title aka ON mh.movie_id = aka.movie_id
LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN movie_link ml ON mh.movie_id = ml.movie_id
WHERE mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, 
    mh.title_kind, aka.name
HAVING COUNT(DISTINCT mc.company_id) >= 1
ORDER BY mh.production_year DESC, mh.title;

This SQL query performs a performance benchmark on the `Join Order Benchmark` schema by utilizing multiple constructs, including:

1. A recursive CTE (`MovieHierarchy`) to represent the hierarchy of movies and their links.
2. Various joins to retrieve related information such as alternative titles, cast information, keywords, and movie companies.
3. Window functions for calculating the average order of roles, using COUNT with FILTER for keyword counts, and employing ROW_NUMBER for ordering results.
4. Conditional aggregation and expressions (like `COALESCE`) for managing NULL values and transforming data, alongside CASE expressions for categorization.
5. A filtering clause in the HAVING statement to ensure only movies with associated companies are returned.
6. A focus on movies produced after the year 2000 for analysis.
