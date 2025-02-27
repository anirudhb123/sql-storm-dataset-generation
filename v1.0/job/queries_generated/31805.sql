WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1,
        mh.path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000 AND NOT m.id = ANY(mh.path)
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    ARRAY_AGG(DISTINCT c.person_id) AS cast_members,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    AVG(mr.info) FILTER (WHERE mr.info IS NOT NULL) AS avg_rating,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mr ON mr.movie_id = mh.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 
ORDER BY 
    avg_rating DESC NULLS LAST, mh.production_year DESC;

### Explanation:
1. **Recursive CTE**: `movie_hierarchy` constructs a hierarchy of movies released after 2000, allowing us to trace linked movies while preventing cycles (using the `NOT m.id = ANY(mh.path)` condition).
  
2. **Outer Joins**: Uses `LEFT JOIN` to gather additional information about the cast, keywords, ratings, and production companies associated with each movie.

3. **Aggregation Functions**:
   - `ARRAY_AGG(DISTINCT c.person_id)` collects unique person IDs from the cast for each movie.
   - `COUNT(DISTINCT mk.keyword_id)` counts how many distinct keywords are associated with each movie.
   - `AVG(mr.info) FILTER (...)` computes the average rating while gracefully handling NULL values.

4. **String Aggregation**: `STRING_AGG(DISTINCT cn.name, ', ')` concatenates unique company names into a single string for each movie.

5. **Complicated HAVING Clause**: Ensures we only return movies that have at least one cast member.

6. **Ordering**: Results are sorted by the average movie rating (with NULLs last) and production year in descending order.

This query provides a comprehensive look at movie statistics while utilizing various advanced SQL features to demonstrate performance and complex relationships in the dataset.
