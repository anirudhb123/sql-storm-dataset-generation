WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 represents 'movie'
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(mk.keyword) AS keyword_count,
    AVG(CASE WHEN CAST(ci.nr_order AS INTEGER) > 0 THEN ci.nr_order ELSE NULL END) AS avg_order,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS non_null_notes_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(mk.keyword) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
JOIN 
    aka_title mt ON mt.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
WHERE 
    mt.production_year > 2000 
    AND (ak.name LIKE '%Smith%' OR ak.name IS NULL)
GROUP BY 
    ak.person_id, mt.id, mt.title, mt.production_year
HAVING 
    COUNT(mk.keyword) > 2
ORDER BY 
    actor_rank, movie_title
LIMIT 100;

### Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE `MovieHierarchy` is created that builds a hierarchy of movies linked to each other.
2. **Joining Tables**: The main query joins several tables, including `aka_name`, `cast_info`, `movie_companies`, `aka_title`, and `movie_keyword` to gather detailed information about movies and actors.
3. **Aggregations**:
   - `COUNT(mk.keyword)`: Counts the related keywords by movie.
   - `AVG(CASE ...)` computes the average actor order while excluding NULLs.
   - `STRING_AGG(DISTINCT mk.keyword, ', ')` aggregates the unique keywords into a single string.
   - `SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END)` counts how many notes are non-null.
4. **Window Function**: `ROW_NUMBER()` ranks actors based on the count of keywords, partitioned by actor.
5. **Filtering**: Only movies from the year 2000 onward are included; names beginning with 'Smith' are prioritized (using `LIKE`) while also allowing for NULL names.
6. **HAVING Clause**: Filters out entries with fewer than 3 associated keywords.
7. **Ordering and Limiting**: Results are ordered by actor rank and movie title and limited to the top 100 results for performance benchmarking.
