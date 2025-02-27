WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mk.keyword_count) AS average_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = ci.movie_id
JOIN 
    title t ON mh.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
) mk ON mk.movie_id = mh.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    average_keywords DESC, movie_title;

### Explanation:
1. **Recursive CTE `MovieHierarchy`:** This hierarchy defines a relationship where a movie may link to another movie as a sequel or a part of a series.
  
2. **Outer Joins:** The query uses left joins to include movies even if they have no associated companies or keywords.

3. **Aggregations:**
   - Counts the distinct companies involved in each movie.
   - Averages the distinct keywords associated with the movies.

4. **Filtering:** The query filters for movies produced from the year 2000 onward and ensures actor names are not NULL.

5. **Grouping and Ordering:** It groups by actor names and movie titles while having conditions to only include movies associated with more than one company. The results are then ordered by the average keywords in descending order, followed by movie title.

This SQL query can serve as a benchmark to test for performance in a complex use case involving multiple tables, aggregations, and CTEs.
