WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id
    FROM
        movie_link ml
    JOIN
        title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS number_of_linked_movies,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movie_titles,
    EXTRACT(YEAR FROM AVG(mh.production_year)::date) AS average_year_of_linked_movies,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 5 THEN 'Popular Actor'
        ELSE 'Less Known Actor'
    END AS actor_popularity,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
GROUP BY
    ak.name, ak.person_id
HAVING
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    number_of_linked_movies DESC;

### Explanation:
1. **Recursive CTE (movie_hierarchy)**: This part constructs a hierarchy of movies linked through the `movie_link` table. It selects movies of the type 'movie' and continues to link them recursively based on their relationships in the `movie_link` table.

2. **Main Query**: 
   - Selects `actor_name` from `aka_name` that is linked with `cast_info`.
   - Counts the number of linked movies for each actor.
   - Uses `STRING_AGG` to combine the titles of linked movies into a single string.
   - Calculates the average production year of linked movies using `AVG()`.

3. **Case Statement**: Determines actor popularity based on the number of linked movies.

4. **Window Function (ROW_NUMBER)**: Ranks actors based on the number of linked movies.

5. **LEFT JOIN**: Ensures actors are included even if they have no linked movies.

6. **HAVING clause**: This filters the results to include only actors linked to at least one movie.

This query collects and organizes comprehensive data on actors and their movie associations in an elaborate manner that showcases diverse SQL constructs for benchmarking performance.
