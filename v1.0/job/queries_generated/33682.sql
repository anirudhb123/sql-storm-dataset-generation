WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS num_movies,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    RANK() OVER (ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank_by_movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office' OR info = 'Budget')
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    num_movies DESC;

### Explanation of the Query:
1. **Recursive CTE (`movie_hierarchy`)**: This common table expression recursively builds a hierarchy of movies linked together, starting from films produced in 2000 or later. It creates a tree-structured format reflecting how movies are interlinked.

2. **Main Select Statement**: The outer query pulls actor names from the `aka_name` table and counts the number of distinct movies they have participated in, calculating the average production year of those movies.

3. **Joining Tables**: 
   - It joins `cast_info` to map actors to movies they're cast in.
   - It further joins the `movie_hierarchy` to pull in all linked movies.
   - An outer join to the `movie_info` table is performed to optionally include movie information such as Box Office and Budget.

4. **Aggregations**: 
   - Utilizes `COUNT` to find how many distinct movies are associated with each actor.
   - `AVG` provides the mean production year of their film work.
   - `STRING_AGG` collects the titles of those movies into a single string, separated by commas.

5. **Ranking**: A window function (`RANK()`) ranks actors based on how many movies they have worked on, allowing for easy identification of the most prolific actors.

6. **Filtering (HAVING)**: The query filters out actors who have appeared in 5 or fewer movies.

7. **Sorting**: Finally, it orders the results by the number of movies, providing a clear and ranked list of actors by their contributions in terms of participating films.
