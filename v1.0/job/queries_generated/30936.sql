WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Starting point for movies after year 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1 AS level
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT k.keyword) AS num_keywords,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown'
        ELSE CAST(m.production_year AS text)
    END AS production_year,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    AVG(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS average_cast_order,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.title) AS row_num
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name p ON p.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    m.production_year IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    p.name, m.title, m.production_year
ORDER BY 
    average_cast_order DESC, num_keywords DESC;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This part creates a hierarchy of movies released after 2000, linking them through the `movie_link` table.
2. **Main Select Statement**: 
   - Joins multiple tables to gather necessary details about actors, movies, keywords, and company types.
   - Uses a `LEFT JOIN` to ensure all movies found in the hierarchy are included, even if they have no associated cast or keywords.
3. **Aggregations and Calculations**:
   - `COUNT(DISTINCT k.keyword)` counts unique keywords associated with each movie.
   - The `CASE` statement provides a fallback for NULL production years.
   - `STRING_AGG` aggregates the distinct company types into a comma-separated string.
   - `AVG` computes the average order of the cast, handling potential NULL values through a conditional.
   - `ROW_NUMBER` assigns a unique number to each resultant row per movie to aid in further analysis or reporting.
4. **Filtering and Grouping**: The `WHERE` clause ensures only movies with a known production year after 2000 are included, and results are grouped by actor name, movie title, and production year.
5. **Ordering**: The final output is ordered by average cast order and number of keywords, helping to identify notable movies with significant actor contributions and thematic relevance.
