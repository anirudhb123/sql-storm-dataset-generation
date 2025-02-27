WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actors AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY a.person_id, ak.name
),
actor_movies AS (
    SELECT 
        ak.name,
        t.title,
        COALESCE(ki.keyword, 'Unknown') AS keyword,
        t.production_year
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN aka_title at ON at.id = c.movie_id
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    JOIN ranked_titles rt ON rt.title_id = at.movie_id
    WHERE ak.name LIKE '%Smith%' AND rt.title_rank <= 3
),
title_info AS (
    SELECT 
        t.id,
        t.title,
        mi.info,
        it.info AS info_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY mi.id) AS info_rank
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
)
SELECT 
    at.name AS actor_name,
    at.title AS movie_title,
    ti.info_type,
    STRING_AGG(ti.info, ', ') AS info_details
FROM actor_movies at
JOIN title_info ti ON ti.title = at.title
GROUP BY at.name, at.title, ti.info_type
HAVING COUNT(ti.info) > 1
ORDER BY actor_name, movie_title DESC;

This SQL query accomplishes several tasks:

1. **Common Table Expressions (CTEs)**: Included CTEs like `ranked_titles` to rank titles per production year, `actors` to get actor counts, and `actor_movies` to collate actor names with associated movie titles and keywords.

2. **Ranked Results**: Used `ROW_NUMBER()` and filtering to accomplish complex ranking criteria.

3. **Outer Joins**: Applied LEFT JOINs to exhibit the possibility of `NULL` keyword scenarios.

4. **String Aggregation**: Employed `STRING_AGG` to merge keyword strings.

5. **Complicated HAVING and GROUP BY**: Showcased handling predicate logic to restrict results based on aggregated counts.

6. **LIKE Predicate**: Incorporated semantic evaluations through pattern matching.

7. **NULL Logic Handling**: Managed potential `NULL` values effectively using `COALESCE`.

This structure is intended for performance benchmarking while exercising advanced SQL features strategically.
