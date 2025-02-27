WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(kt.kind, 'Unknown') AS kind,
        1 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        amt.title,
        amt.production_year,
        COALESCE(kt.kind, 'Unknown') AS kind,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.id
    JOIN 
        aka_title amt ON ml.linked_movie_id = amt.id
    LEFT JOIN 
        kind_type kt ON amt.kind_id = kt.id
)

SELECT 
    mv.title AS root_movie_title,
    mv.production_year AS root_movie_year,
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    mh.kind AS linked_movie_kind,
    mh.level AS connection_level
FROM 
    movie_hierarchy mh
JOIN 
    aka_title mv ON mh.root_movie_id = mv.id
WHERE 
    mh.level <= 3
ORDER BY 
    mv.title, mh.level, mh.production_year DESC;

-- Performance benchmarking aspect with aggregate function
SELECT 
    COUNT(DISTINCT (mh.root_movie_id)) AS unique_root_movies,
    AVG(mh.level) AS average_connection_level
FROM 
    movie_hierarchy mh
WHERE 
    mh.level <= 3;

### Explanation:
1. **Recursive CTE** (`movie_hierarchy`): It captures the linked movies starting from `aka_title` where production year is 2000 or later and allows traversing through linked movies.
  
2. **Main Selection**: This part selects the titles and production years of the root movie and its linked movies' details, limiting the connection depth to 3 levels and ordering results for readability.

3. **Performance Benchmarking**: The final aggregation part computes the number of unique root movies and the average connection level across the hierarchy, allowing for metrics that can assist in performance assessment.

The query utilizes various SQL constructs such as joins, CTEs, aggregates, and orderings, promoting readability and depth of information retrieval, which contributes to performance benchmarking.
