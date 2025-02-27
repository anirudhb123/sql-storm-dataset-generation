WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    MAX(mh.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT mh.path, ', ') AS movie_paths,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS average_order,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
FROM 
    cast_info c
INNER JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC, last_movie_year DESC;

**Explanation of Constructs Used:**

1. **CTE (Common Table Expression)**: A recursive CTE `movie_hierarchy` is created to traverse and build a hierarchy of movies based on links between them.
  
2. **Aggregate Functions**: 
   - `COUNT(DISTINCT c.movie_id)` counts the total number of unique movies each actor has appeared in.
   - `MAX(mh.production_year)` retrieves the year of the actor's most recent movie.
   - `STRING_AGG` concatenates different movie paths obtained from the recursive CTE.
   - `AVG` and `SUM` calculate average `nr_order` and count of non-null notes respectively.

3. **Joins**: Inner and left joins are utilized to bring together data from different tables whilst handling cases where movie links might not exist.

4. **HAVING and GROUP BY**: Used to filter results based on the required condition of actors having appeared in more than 5 movies.

5. **NULL Logic**: Utilizes conditional logic to handle potential NULL values in the `nr_order` and `note` columns.

6. **Ordering**: The result is ordered by the number of movies and then by the most recent production year, allowing benchmarking of actor contributions.
