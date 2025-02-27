WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS text) AS path
    FROM title m
    WHERE m.episode_of_id IS NULL  -- Start with top-level movies (not episodes)

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || e.title AS text) AS path
    FROM title e
    JOIN MovieHierarchy mh ON e.episode_of_id = mh.movie_id  -- Join on episodes
)
, MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        mh.path,
        COALESCE(AVG(mk_count.keyword_count), 0) AS avg_keywords,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM MovieHierarchy mh
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS keyword_count
        FROM movie_keyword
        GROUP BY movie_id
    ) mk_count ON mh.movie_id = mk_count.movie_id
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN aka_name c ON cc.subject_id = c.person_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
)
SELECT 
    md.title,
    md.production_year,
    md.level,
    md.path,
    md.avg_keywords,
    STRING_AGG(DISTINCT md.cast_names, ', ') AS cast_list
FROM MovieDetails md
JOIN title t ON md.movie_id = t.id
WHERE md.avg_keywords > 0  -- Filter movies with keywords
ORDER BY md.level, md.production_year DESC
LIMIT 10;
This SQL query does the following:

1. **Recursive Common Table Expression (CTE)**: `MovieHierarchy` builds a hierarchy of movies and their episodes, starting from top-level movies (those that are not episodes). It tracks the depth of the hierarchy.
  
2. **Calculating Keywords**: `MovieDetails` aggregates the information about each movie, including the average number of keywords associated with the movie and the names of the cast members.

3. **Final Selection**: The outer query selects the movie title, production year, hierarchy level, path (showing hierarchy), average keyword count, and a list of cast names. It filters out any movies that have no associated keywords and limits the result to 10 entries.

4. **String Aggregation**: Uses `STRING_AGG` to combine cast names into a single string for each movie.

5. **Ordering**: Finally, the results are ordered by hierarchy level and production year descending, showing the structure and recency of the films. 

This demonstrates various SQL constructs such as CTEs, joins, aggregate functions, filtering, and ordering, which can be useful for performance benchmarking on a complex schema.
