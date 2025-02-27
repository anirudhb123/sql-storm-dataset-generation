WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        1 AS depth
    FROM 
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    grp.production_year,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    MAX(mh.depth) AS max_depth,
    STRING_AGG(DISTINCT CONCAT(mh.title, ' (', mh.production_year, ')'), ', ') AS linked_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN (
    SELECT 
        production_year,
        ARRAY_AGG(DISTINCT movie_id) AS movies
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        production_year
    HAVING 
        COUNT(movie_id) > 5
) grp ON mh.production_year = grp.production_year
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, grp.production_year
ORDER BY 
    actor_name, production_year DESC;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: Starts from movies released after 2000 and recursively finds linked movies, capturing the relationship depth.
   
2. **Aggregating actor data**: Joins the actors' names with their roles, filtering by movies in the recursive CTE.

3. **Subquery (`grp`)**: Identifies production years with more than 5 movies that have a specific info type (rating).

4. **Aggregation Functions**:
   - `COUNT(DISTINCT mh.movie_id)`: Counts unique movies for each actor in the specified production year.
   - `MAX(mh.depth)`: Determines the maximum depth of linked movies.
   - `STRING_AGG`: Concatenates the titles of linked movies along with their production years.

5. **Final Grouping and Ordering**: Groups results by actor name and production year, ordering them for better readability. 

This query is useful for performance benchmarking due to its complexity and use of various SQL constructs.
