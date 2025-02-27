WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        COALESCE(mc.note, 'No Company') AS company_note,
        1 AS level
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.note, 'No Company') AS company_note,
        mh.level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.company_note,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actor_names,
    SUM(CASE 
            WHEN pi.info_type_id = 1 THEN pi.info::int 
            ELSE 0 
        END) AS total_info_type_1
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_info AS ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    aka_name AS ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_info AS mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info AS pi ON ca.person_id = pi.person_id
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.company_note
HAVING 
    COUNT(DISTINCT ca.person_id) > 0
ORDER BY 
    total_info_type_1 DESC NULLS LAST
LIMIT 10
OFFSET 5;

### Explanation:

1. **CTE (Common Table Expression) `movie_hierarchy`:** 
   - A recursive CTE is created to collect movies along with their associated companies, iteratively finding linked movies.
  
2. **LEFT JOINs:** 
   - Joins are performed to gather data from various tables, including `movie_companies`, `cast_info`, and `person_info`, ensuring that all movies are included even if they have none of the associated `companies` or `cast`.

3. **COUNT and STRING_AGG Aggregation:** 
   - The query calculates the count of distinct actors for each movie, named `actor_count`, and aggregates the actor names using `STRING_AGG`, ensuring that NULL names are excluded.

4. **Conditional Aggregation with CASE:** 
   - Total information of a specific type is computed using a `SUM` with `CASE`, which distinguishes based on `info_type_id`.

5. **Complicated HAVING Clause:** 
   - The `HAVING` clause filters out results that do not have any associated actors.

6. **ORDER BY with NULLS LAST:** 
   - The results are ordered by `total_info_type_1`, with handling of NULLs last.

7. **LIMIT and OFFSET:** 
   - Applied at the end to paginate the result set, fetching a specific subset of the first records.

This query may serve performance benchmarking while examining a hierarchical relationship between movies, cast, and their associated information types across multiple tables, alongside handling NULLs, complex predicates, and unusual semantics.
