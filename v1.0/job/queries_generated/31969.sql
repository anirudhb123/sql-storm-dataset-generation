WITH RECURSIVE MovieHierarchy AS (
    -- Base case: start with all movies
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM
        aka_title mt

    UNION ALL

    -- Recursive case: find linked movies
    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    MAX(mh.depth) AS max_link_depth,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    COUNT(DISTINCT ci.person_role_id) AS unique_roles
FROM 
    movie_companies mc
JOIN 
    aka_title mt ON mc.movie_id = mt.id
JOIN 
    cast_info ci ON ci.movie_id = mt.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    mt.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
ORDER BY 
    max_link_depth DESC, production_company_count DESC;

### Explanation:
1. **CTE (With RECURSIVE)**: We create a recursive CTE named `MovieHierarchy`. It starts by selecting all movies from `aka_title`. The recursive part finds all linked movies via `movie_link`, allowing us to construct a hierarchy.
  
2. **Outer Joins**: We're using a LEFT JOIN on `movie_keyword` and `keyword` to ensure that we still get movie entries even if they don't have associated keywords.

3. **Aggregations and Calculations**:
   - `MAX(mh.depth)` calculates the maximum depth of movie links, indicating how many layers deep linked movies go.
   - `COUNT(DISTINCT mc.company_id)` counts the unique production companies for each movie.
   - `STRING_AGG(DISTINCT k.keyword, ', ')` aggregates all unique keywords, filtering out `NULL` values.

4. **Complicated Predicate**: The WHERE clause limits the results to movies produced in or after 2000. 

5. **Grouping and Ordering**: The final selection groups results by actor and movie details, ordering primarily by maximum link depth and then by the number of distinct production companies.

This structured query showcases multiple SQL features, ensuring performance benchmarks are accurate in complex, real-world data environments.
