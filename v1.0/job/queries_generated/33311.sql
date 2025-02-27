WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        0 AS hierarchy_level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE title LIKE '%Star Wars%')
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.hierarchy_level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ci.movie_id IN (
            SELECT linked_movie_id 
            FROM movie_link 
            WHERE movie_id = (SELECT movie_id FROM movie_companies WHERE company_id IN (
                SELECT id FROM company_name WHERE country_code = 'USA'
            ))
        )
    JOIN 
        aka_name a ON ci.person_id = a.person_id
)
SELECT 
    actor_hierarchy.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    MAX(at.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT at.title, ', ') AS movies,
    AVG(CASE 
            WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office') 
            THEN CAST(mi.info AS FLOAT)
            ELSE NULL 
        END) AS avg_box_office,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM 
    actor_hierarchy
JOIN 
    cast_info ci ON actor_hierarchy.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
GROUP BY 
    actor_hierarchy.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5 AND MAX(at.production_year) > 2000
ORDER BY 
    movie_count DESC, latest_movie_year DESC;

### Explanation:
1. **Recursive CTE** (`actor_hierarchy`): This recurses through cast_info to find actors connected to a specific set of movies (in this case, those related to "Star Wars"). It establishes relationships to uncover more actors who are indirectly involved in similar productions.

2. **Core SELECT**: In the main select statement, it aggregates data:
   - Counts movies acted in by each actor.
   - Determines the latest movie year.
   - Collates movie titles into a comma-separated string.
   - Computes average box office revenue where applicable (using conditional aggregation).
   - Counts associated keywords for each actor.

3. **JOINs**: It joins various tables to correlate movies, actors, their keywords, and any additional movie info like box office earnings.

4. **HAVING Clause**: Filters to only include actors who have acted in more than 5 movies since the year 2000.

5. **Ordering**: Finally, it orders the results by the number of movies acted in, and then by the most recent movie year.

This query provides deep insights into the performance and connections of actors associated with a specific theme in movies while utilizing advanced SQL features for true analytical depth.
