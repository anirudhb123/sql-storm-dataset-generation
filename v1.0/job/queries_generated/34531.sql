WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Considering only feature films
    
    UNION ALL
    
    SELECT 
        mt2.id AS movie_id,
        mt2.title,
        mt2.production_year,
        level + 1
    FROM 
        aka_title mt2
    INNER JOIN 
        RecursiveMovieCTE rmt ON mt2.episode_of_id = rmt.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mci.id) AS num_companies,
    AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) * 100 AS percent_with_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RecursiveMovieCTE t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_companies mci ON t.movie_id = mci.movie_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id IN (1, 2) -- Assuming 1=Age, 2=Gender
GROUP BY 
    a.id, a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mci.id) > 0
ORDER BY 
    movie_rank, percent_with_info DESC;

### Explanation:
- **Recursive CTE (`RecursiveMovieCTE`)**: This part builds a hierarchy of movies, allowing the query to include episodes and their respective series.
- **JOINs**: The `aka_name`, `cast_info`, and the recursive movie CTE help link actors to their respective movies.
- **LEFT JOINs**: Include optional company and keyword data, as well as personal information related to each actor.
- **Aggregation**: Count distinct movie companies associated with each movie, calculate the percentage of actors who have additional information, and concatenate keywords into a single string.
- **Window Functions**: Utilize `ROW_NUMBER()` to rank movies for each actor based on their production year.
- **HAVING and ORDER BY clauses**: Ensure only actors with associated companies appear in the results and sort results meaningfully for analysis.
