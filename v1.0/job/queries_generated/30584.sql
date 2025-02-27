WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255))
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(COALESCE(pi.info_type_id, 0)) AS avg_info_type,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS main_actors_count
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    person_info pi ON ci.person_id = pi.person_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.depth, mh.path
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    mh.production_year DESC,
    actor_count DESC,
    mh.path;

This query performs the following actions:

1. **Recursive CTE (MovieHierarchy)**: It constructs a hierarchy of linked movies since the year 2000, tracking the depth and path of the movie titles.
  
2. **Main Query**: It selects movie details from this hierarchy and counts the number of unique actors in each movie, averaging their info types and aggregating company names associated with the movies.

3. **Outer Joins**: It uses several LEFT JOINs to pull in data from the `complete_cast`, `cast_info`, `movie_companies`, `company_name`, and `person_info` tables.

4. **Aggregations & Conditions**: It applies GROUP BY and HAVING clauses to filter movies with a significant number of actors, further enriching the output with actor and company details.

5. **Ordered Output**: Finally, it sorts the results by the production year, actor count, and the movie path. 

This provides a broad view of the movie landscape, showing how connected productions are, the actors involved, and the companies that produced them, allowing for insightful benchmarking.
