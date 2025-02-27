WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NULL  -- Get top-level movies

    UNION ALL

    SELECT 
        me.id AS movie_id,
        me.title AS movie_title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title me
    JOIN 
        movie_link ml ON me.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.level,
    COALESCE(k.keyword, 'No Keyword') AS keyword,
    COALESCE(pm.actor_count, 0) AS actor_count,
    CASE 
        WHEN mh.level > 1 THEN 'Child Movie'
        ELSE 'Top-level Movie'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) pm ON pm.movie_id = mh.movie_id
ORDER BY 
    mh.level, mh.movie_title;

### Explanation:
1. **Recursive CTE**: The `MovieHierarchy` CTE recursively collects movies and their linked movies, establishing a parent-child relationship based on `movie_link`.
2. **Outer Joins**: The final query uses `LEFT JOIN`s to connect the hierarchy from `MovieHierarchy` to `movie_keyword` and `keyword` tables, ensuring we retrieve all movies regardless of whether they have keywords.
3. **Aggregated Subquery**: A derived table (`pm`) counts the number of distinct actors for each movie in the `cast_info` table, allowing us to display the actor count alongside each movie.
4. **COALESCE**: Used to handle possible NULL values for keywords and actor counts, providing defaults.
5. **CASE Statement**: Determines if a movie is a "Child Movie" (has a parent) or a "Top-level Movie" based on its hierarchy level.
6. **Ordering**: The final output is ordered first by `level` then by `movie_title`, making it easy to understand the hierarchy visually.

This complex query tests performance with a deep hierarchy, outer joins, subqueries, and window functions, showcasing various constructs of SQL functionality.
