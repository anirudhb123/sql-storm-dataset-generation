WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    SUM(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS row_num
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2 
    AND SUM(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    a.name, t.production_year DESC
LIMIT 100;

### Explanation of the Query Components:

1. **Common Table Expression (CTE)**: The `movie_hierarchy` CTE creates a recursive relationship for movies and their linked movies, particularly focusing on those produced from the year 2000 onwards.

2. **Main Query**: The main body of the SQL retrieves actor names and titles of movies they have participated in, alongside various aggregations:
   - `COUNT(DISTINCT mc.company_id)`: Counts the number of distinct production companies involved in each movie.
   - `ARRAY_AGG(DISTINCT k.keyword)`: Collects distinct keywords associated with the movie into an array.
   - `SUM(CASE ...)`: Counts the number of info entries related to the actor to check for additional information presence.

3. **JOINs**: Utilizes multiple joins:
   - `aka_name` joins with `cast_info` to link actors to titles.
   - `title` links to both `movie_companies` and `movie_keyword` to gather relevant company and keyword information.
   - An additional `LEFT JOIN` with `person_info` checks for more info about the actors.

4. **WHERE Clause**: Ensures the actor's name and the movie's production year are not NULL.

5. **GROUP BY**: Aggregates results by actor name and movie title/year for distinct counting and aggregation.

6. **HAVING Clause**: Filters results to ensure that movies have at least two distinct production companies and that the actors have some info.

7. **ORDER BY and LIMIT**: Orders records by actor name and production year in descending order while limiting results to the top 100. 

This SQL query is complex, includes multiple SQL concepts, and is designed to benchmark performance based on various joins, aggregates, and window functions.
