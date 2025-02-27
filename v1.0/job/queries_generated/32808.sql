WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id as movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 as depth
    FROM
        aka_title m
    WHERE
        m.id IS NOT NULL

    UNION ALL

    SELECT
        mv.id,
        mv.title,
        mv.production_year,
        mv.kind_id,
        mh.depth + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mv ON ml.linked_movie_id = mv.id
)

SELECT
    a.name AS actor_name,
    at.title AS title,
    at.production_year,
    kc.keyword AS keyword,
    COUNT(mh.movie_id) AS linked_movie_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY at.production_year DESC) AS rn
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND at.production_year >= 2000
    AND (ci.nr_order > 1 OR ci.nr_order IS NULL)
GROUP BY
    a.name, at.title, at.production_year, kc.keyword
HAVING
    COUNT(mh.movie_id) > 1
    OR AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order END) < 10
ORDER BY
    average_order DESC, actor_name;

### Query Explanation:

1. **Recursive CTE (`movie_hierarchy`)**: 
   - It starts with the base movies from `aka_title` and recursively fetches linked movies through `movie_link`, allowing us to visualize a multi-level relationship of movies.

2. **Main SELECT Statement**: 
   - We extract actor names from `aka_name` and join to `cast_info` and `aka_title` to fetch movie titles and production years.
   - Utilizes a **LEFT JOIN** on `movie_keyword` and `keyword` to gather keywords associated with each movie while ensuring that we do not miss movies without keywords.
   - The `WHERE` clause filters for movies produced after the year 2000 and checks for correlated `nr_order` values in `cast_info`.

3. **Aggregation**:
   - Counts linked movies using `COUNT(mh.movie_id)`.
   - Calculates the average `nr_order` of the actor's roles using a conditional average inside an aggregation.
  
4. **Window Function**:
   - The `ROW_NUMBER()` function is used to rank movies for each actor based on production year.

5. **Filtering with HAVING**:
   - Only selects those rows that meet the criteria of having more than one linked movie or below a certain average `nr_order`.

6. **Final Sorting**:
   - Results are ordered by the computed average order descending and then by actor name for a clearer output.
