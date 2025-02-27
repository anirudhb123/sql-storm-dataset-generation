WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(mi.note IS NOT NULL)::int AS has_extra_info,
    RANK() OVER (PARTITION BY ak.id ORDER BY mh.depth) AS movie_rank,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS is_lead_role
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
JOIN
    aka_title mt ON mh.movie_id = mt.id
WHERE
    ak.name IS NOT NULL
    AND mh.production_year >= 2000
GROUP BY
    ak.id, mt.id, mh.production_year
ORDER BY
    actor_name, movie_rank;

### Explanation of Query Constructs:
1. **CTE (Common Table Expression)**: The `movie_hierarchy` CTE is a recursive query that builds a hierarchy of movies and their linked movies. It starts with the main movies and then recursively finds the linked movies.

2. **Window Function**: The `RANK()` function is used to rank movies based on their depth in the hierarchy for each actor.

3. **LEFT JOINs**: These are used to include movie companies and keywords even if some movies don't have associated entries for those tables.

4. **Aggregations**: The query counts distinct company IDs and aggregates keywords into a single string, demonstrating set operations.

5. **Case Expression**: The `MAX(CASE WHEN ...)` is used to determine if there is at least one lead role among cast info for each actor.

6. **Filter Conditions**: The WHERE clause includes conditions that filter out NULL names and restricts the production year to after 2000.

7. **String Aggregation**: The `STRING_AGG` function creates a comma-separated list of keywords for movies.

This query serves as a comprehensive performance benchmark, involving multiple SQL constructs, aggregations, joins, and filtering, to provide insights into the actors and their connected movies.
