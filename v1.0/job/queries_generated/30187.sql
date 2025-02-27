WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS full_path
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        mh.level + 1,
        CAST(mh.full_path || ' -> ' || e.title AS VARCHAR(255)) AS full_path
    FROM 
        title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    t.title AS main_movie,
    STRING_AGG(DISTINCT ch.name, ', ') AS child_movies,
    t.production_year,
    COALESCE(AVG(CASE WHEN ci.person_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_cast_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    MovieHierarchy t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    aka_title ka ON t.movie_id = ka.movie_id
LEFT JOIN 
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN 
    char_name ch ON ch.imdb_id = ka.kind_id
WHERE 
    t.production_year > 2000
GROUP BY 
    t.title, t.production_year
ORDER BY 
    t.production_year DESC;

### Explanation:
- **Common Table Expression (CTE)**: The recursive CTE `MovieHierarchy` builds a hierarchy of movies considering episodes and their corresponding parent titles.
- **Outer Joins**: Multiple outer joins are used to link related tables such as `complete_cast`, `cast_info`, `movie_keyword`, `aka_title`, and `char_name`.
- **Aggregations**: The `STRING_AGG` function collects names and keywords into a comma-separated string.
- **COALESCE**: Used to replace NULL values with zero for average calculations.
- **Complicated Predicates**: The query uses conditions to filter results based on the production year (greater than 2000).
- **Window Functions**: Although not overtly stated in this query, window functions could be easily integrated for more advanced analytics if needed.
