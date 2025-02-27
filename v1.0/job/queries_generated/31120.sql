WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name,
    m.title AS movie_title,
    m.production_year,
    co.name AS company_name,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(FORMAT(pg.rating, '999.99')) AS avg_rating,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    m.level AS hierarchy_level
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN (
    SELECT 
        movie_id, 
        ROUND(AVG(rating), 2) AS rating
    FROM 
        movie_info 
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        movie_id
) pg ON pg.movie_id = m.movie_id
WHERE 
    m.production_year IS NOT NULL 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, m.title, m.production_year, co.name, m.level
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    m.production_year DESC, actor_count DESC;

### Explanation of the SQL Query Components:
1. **Recursive CTE**: A Common Table Expression (CTE) named `movie_hierarchy` is used to create a hierarchy of movies and their linked movies, allowing for exploration of connected movies up to any level.

2. **Aggregations**: The query counts the number of distinct actors per movie and calculates the average movie rating.

3. **JOINs**: It includes various joins between tables to get relevant data such as movie titles, production years, actor names, and associated companies.

4. **LEFT JOINs**: These are employed with `movie_companies` and `movie_keyword` to gather additional metadata about company involvement and keywords, respectively, allowing for null handling.

5. **GROUP BY with HAVING**: Results are aggregated by actor names, movie titles, years, and company names, with a HAVING clause filtering for movies involving more than two actors.

6. **ORDER BY**: Finally, results are ordered by production year in descending order and then by actor count, providing meaningful rankings.

7. **Formatting Functions**: Usage of `FORMAT` to control decimal representation in ratings, showcasing string expressions in calculations. 

This query provides a comprehensive insight into the movie landscape within the given schema, showing intricate relationships and aspects of the data while also implementing various SQL constructs for performance benchmarking.
