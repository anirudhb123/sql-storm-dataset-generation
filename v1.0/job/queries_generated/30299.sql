WITH RECURSIVE film_hierarchy AS (
    SELECT 
        mt.id AS film_id,
        mt.title AS film_title,
        mt.production_year,
        1 AS level
    FROM title mt
    WHERE mt.production_year BETWEEN 1990 AND 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS film_id,
        (SELECT title FROM title WHERE id = ml.linked_movie_id) AS film_title,
        (SELECT production_year FROM title WHERE id = ml.linked_movie_id) AS production_year,
        fh.level + 1
    FROM movie_link ml
    JOIN film_hierarchy fh ON ml.movie_id = fh.film_id
),
actor_film_info AS (
    SELECT 
        ka.name AS actor_name,
        ft.film_title,
        ft.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY ft.production_year) AS film_order
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN title ft ON ci.movie_id = ft.id
),
film_statistics AS (
    SELECT 
        film_id,
        COUNT(*) AS actor_count,
        AVG(film_order) AS avg_film_order
    FROM actor_film_info
    GROUP BY film_id
)
SELECT 
    f.film_title,
    f.production_year,
    COALESCE(fs.actor_count, 0) AS actor_count,
    COALESCE(fs.avg_film_order, 0) AS avg_film_order,
    CASE 
        WHEN fs.actor_count IS NULL THEN 'No actors found'
        ELSE 'Actors found'
    END AS actor_status
FROM film_hierarchy f
LEFT JOIN film_statistics fs ON f.film_id = fs.film_id
WHERE f.level = (SELECT MAX(level) FROM film_hierarchy)
ORDER BY f.production_year DESC, f.film_title;

### Query Explanation:
1. **Recursive CTE (`film_hierarchy`)**: This CTE creates a hierarchy of films starting from original films produced between 1990 and 2000 and recursively finds linked films.
2. **Actor Film Info CTE (`actor_film_info`)**: This CTE extracts actor names, their films, production years, and assigns a row number to each film ordered by production year for each actor.
3. **Film Statistics CTE (`film_statistics`)**: This calculates the total number of actors and the average film order for each film.
4. **Main Query**: The final query selects details from the film hierarchy, joins with statistics, and adds logic to handle cases where no actors are found, ensuring that NULL values are appropriately handled with `COALESCE`. It filters results to the deepest level in the hierarchy and orders the results by production year and film title.
