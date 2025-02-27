WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)

SELECT 
    a.name AS actor_name,
    title.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS valid_order_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS ranking,
    NULLIF(COALESCE(m.production_year, 0), 0) AS safe_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title title ON ci.movie_id = title.id
LEFT JOIN 
    movie_keyword mk ON title.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON title.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND title.production_year > 2000
    AND title.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'episode'))
GROUP BY 
    a.name, title.id, m.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    safe_year DESC, actor_count DESC;

### Query Explanation:
1. **Recursive CTE (Common Table Expression)**: The `MovieHierarchy` CTE recursively builds a hierarchy of movies to link episodes to their parent series.
2. **Main Select**: The query selects actor names and their corresponding movie titles while counting the unique actors, valid order entries, and associated keywords related to the movies released after 2000.
3. **Joins**: Multiple tables are joined:
   - `aka_name` for actor details.
   - `cast_info` links actors to movies.
   - `aka_title` retrieves movie details.
   - `movie_keyword` fetches associated keywords.
   - `MovieHierarchy` helps connect episodic relationships.
4. **NULL Handling**: `NULLIF` and `COALESCE` manage potential null values in the year.
5. **Window Function**: `ROW_NUMBER()` ranks movies based on their keyword count within the same production year.
6. **Filters**: The `WHERE` and `HAVING` clause ensure only relevant data is processed (2000+ movies and a minimum keyword count).
7. **Ordering**: The final results are sorted by `safe_year` and actor count to prioritize the most recent and highest-appearing actors.
