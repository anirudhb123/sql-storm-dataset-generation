WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT mk.movie_id) AS keyword_count,
    AVG(COALESCE(mb.budget, 0)) AS avg_budget,
    MAX(mk.production_year) AS latest_year
FROM 
    movie_keyword mk
LEFT JOIN 
    (SELECT 
         m.id AS movie_id,
         mi.info AS budget
     FROM 
         title m
     LEFT JOIN 
         movie_info mi ON mi.movie_id = m.id 
     WHERE 
         mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    ) mb ON mk.movie_id = mb.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mk.movie_id = mh.movie_id
WHERE 
    mh.level = 1 AND
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
ORDER BY 
    keyword_count DESC
LIMIT 10;

### Explanation:
1. **CTE (Common Table Expression)**:
   - A recursive CTE named `MovieHierarchy` builds a hierarchy of movies linked by `movie_link`. This allows for exploring relationships between different movies over multiple levels of connections.

2. **Main Query**:
   - The main query aggregates keyword usage across movies. 
   - It selects distinct keywords and counts how many different movies each keyword is associated with (`keyword_count`).
   - It computes the average budget of the movies associated with each keyword. The budget is retrieved from a subquery that joins `title` with `movie_info`, filtering info related to budget.
   - It identifies the latest production year for the movies associated with each keyword.

3. **Joins & Conditions**:
   - A LEFT JOIN pulls in budget info for movies filtered by the info type of 'budget' to handle nulls effectively.
   - Filtering to ensure only first-level movies from the `MovieHierarchy` are considered.
   - Ensures only non-null keywords are processed.

4. **Ordering and Limiting**:
   - It sorts results by the `keyword_count` in descending order, providing the top 10 results based on keyword popularity.

This SQL query includes various advanced SQL constructs, fulfilling criteria for performance benchmarking in complex data environments.
