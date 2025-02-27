WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, m.production_year, mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN aka_title linked ON linked.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.depth < 3
), 
CastRoles AS (
    SELECT DISTINCT ci.movie_id, rt.role, COUNT(ci.person_id) AS num_of_actors
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
MoviesWithActors AS (
    SELECT mh.movie_id, mh.title, mh.production_year, cr.role, cr.num_of_actors,
           ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cr.num_of_actors DESC) AS role_rank
    FROM MovieHierarchy mh
    LEFT JOIN CastRoles cr ON mh.movie_id = cr.movie_id
)
SELECT m.title,
       m.production_year,
       m.role,
       COALESCE(m.num_of_actors, 0) AS actor_count,
       CASE 
           WHEN m.num_of_actors IS NULL THEN 'No actors'
           WHEN m.num_of_actors <= 2 THEN 'Few actors'
           ELSE 'Many actors'
       END AS actor_description,
       STRING_AGG(DISTINCT CASE WHEN m.num_of_actors IS NULL THEN 'Unknown' ELSE m.role END, ', ') AS roles_summary
FROM MoviesWithActors m
LEFT JOIN aka_name an ON an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.movie_id)
WHERE m.depth = 2
GROUP BY m.title, m.production_year, m.role, m.num_of_actors
HAVING COUNT(an.id) > 0
ORDER BY m.production_year DESC, actor_count DESC
LIMIT 100;

### Explanation of the Query:

1. **CTE MovieHierarchy**: This Common Table Expression (CTE) recursively retrieves a hierarchy of movies released after 2000, linking them through an assumed `movie_link` table to explore connections up to a depth of 3.

2. **CTE CastRoles**: This CTE aggregates the number of actors per role associated with each movie, allowing for differentiation between various roles held by actors in a given movie.

3. **CTE MoviesWithActors**: This CTE combines the hierarchy of movies with the cast role data and ranks the roles based on the number of actors using `ROW_NUMBER()`.

4. **Final SELECT**: The main query retrieves movie titles, years, roles, and actor counts. It utilizes the `COALESCE()` function to provide a default count of 0 for movies with no actors. It also includes a case statement for actor descriptions. 

5. **STRING_AGG()**: The query concatenates unique roles for each movie into a single summary string. 

6. **Filters and Grouping**: Grouped by title and year, and filtered to include only those movies with at least one associated actor. 

7. **Sorting and Limiting**: Finally, it sorts results in descending order by year and actor count, limiting the output to the top 100 results. 

This multi-layered, complex query leverages several SQL features showcasing a range of advanced SQL functionality, including recursive CTEs, aggregation, window functions, and conditional logic, while addressing potentially tricky NULL handling scenarios.
