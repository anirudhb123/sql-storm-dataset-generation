WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies and their direct cast members
    SELECT
        mt.id AS movie_id,
        mt.title,
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        aka_title mt
    JOIN
        cast_info c ON mt.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    
    UNION ALL
    
    -- Recursive case: Find related movies by links (sequel/prequels)
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        NULL AS person_id,
        NULL AS actor_name,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT
    mh.movie_id,
    mh.title,
    COALESCE(mh.actor_name, 'Not Available') AS actor_name,
    COUNT(CASE WHEN mh.actor_name IS NOT NULL THEN 1 END) OVER (PARTITION BY mh.movie_id) AS total_cast,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS notes_count,
    STRING_AGG(DISTINCT c.note, '; ') AS notes_details
FROM
    MovieHierarchy mh
LEFT JOIN
    cast_info c ON mh.person_id = c.person_id
GROUP BY
    mh.movie_id, mh.title, mh.actor_name
HAVING
    total_cast > 2
ORDER BY
    mh.title ASC,
    total_cast DESC;

### Explanation:

1. **Recursive CTE (`MovieHierarchy`)**: This part of the query constructs a hierarchy of movies and their linked movies (e.g., sequels or prequels). The base case selects movies with their cast, while the recursive part finds linked movies iteratively.

2. **Main Query**:
   - It selects relevant information about each movie, actor names, total cast count, and any notes associated with the cast.
   - Uses `COALESCE` to handle NULL values for actor names, ensuring output is user-friendly.
   - `COUNT` and `SUM` functions are used as window functions to calculate totals and counts within their respective partitions (in this case, by `movie_id`).
   - `STRING_AGG` is utilized to concatenate notes if they exist, with a semicolon separator.

3. **Filtering with `HAVING`**: Ensures only movies with more than 2 cast members are included in the results.

4. **Ordering**: The final output is ordered first by the movie title in ascending order and then by total cast members in descending. 

This complex SQL query is designed to assess performance while handling various SQL features ranging from joins, window functions, and hierarchy creation, which may considerably impact execution time.
