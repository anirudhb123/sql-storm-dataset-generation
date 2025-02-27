WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.name ILIKE '%Smith%'  -- Start with actors whose name includes 'Smith'

    UNION ALL

    SELECT 
        ci2.person_id,
        ci2.movie_id,
        ah.depth + 1
    FROM 
        cast_info ci2
    JOIN 
        ActorHierarchy ah ON ci2.movie_id = ah.movie_id 
    WHERE 
        ci2.person_id != ah.person_id -- Prevent circular references
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(distinct ah.person_id) AS number_of_actors,
    AVG(ah.depth) AS avg_depth,
    string_agg(DISTINCT co.name, ', ') AS company_names
FROM 
    ActorHierarchy ah
JOIN 
    aka_name a ON ah.person_id = a.person_id
JOIN 
    title t ON ah.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(distinct ah.person_id) > 1
ORDER BY 
    avg_depth DESC, number_of_actors DESC
LIMIT 10;

### Explanation:
1. **Common Table Expression (CTE)**: 
   - A recursive CTE (`ActorHierarchy`) is used to identify connections through films that actors have been involved in, starting with actors whose name contains 'Smith'.
  
2. **Joins**:
   - Several joins are used to tie together information from various tables, including `cast_info`, `aka_name`, `title`, `movie_companies`, and `company_name`.
   
3. **Aggregate Functions**:
   - The query counts distinct actors (`COUNT(distinct ah.person_id)`), calculates the average depth of connections (`AVG(ah.depth)`), and combines company names into a single string (`string_agg(DISTINCT co.name, ', ')`).

4. **Filtering and Ordering**:
   - The `WHERE` clause filters movies produced between 2000 and 2023, and the `HAVING` clause ensures that only movies with more than one distinct actor are included. The result is ordered by average depth and number of actors.

5. **Limit**: 
   - The final result is limited to the top 10 entries based on the sorting criteria, making it efficient for performance benchmarking.
