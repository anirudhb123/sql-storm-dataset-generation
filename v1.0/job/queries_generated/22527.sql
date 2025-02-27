WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title AS mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link AS ml
    JOIN
        title AS m ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),
actor_movie_counts AS (
    SELECT
        cast.person_id,
        COUNT(DISTINCT cast.movie_id) AS total_movies
    FROM
        cast_info AS cast
    JOIN
        movie_hierarchy AS mh ON cast.movie_id = mh.movie_id
    GROUP BY
        cast.person_id
    HAVING
        COUNT(DISTINCT cast.movie_id) > 5
),
actor_details AS (
    SELECT
        a.name,
        a.id AS actor_id,
        COALESCE(info.info, 'No Info') AS additional_info,
        ac.total_movies
    FROM
        aka_name AS a
    LEFT JOIN
        actor_movie_counts AS ac ON a.person_id = ac.person_id
    LEFT JOIN
        person_info AS info ON a.person_id = info.person_id
        AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio') -- correlated subquery
),
top_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rn
    FROM
        movie_hierarchy AS mh
    WHERE
        mh.depth <= 2
)
SELECT
    ad.name AS actor_name,
    ad.additional_info,
    tm.title AS top_movie,
    tm.production_year,
    ad.total_movies
FROM
    actor_details AS ad
JOIN
    top_movies AS tm ON ad.total_movies IS NOT NULL -- ensuring we only join actors with valid movie counts
WHERE
    ad.total_movies > (SELECT AVG(total_movies) FROM actor_movie_counts)
ORDER BY
    ad.total_movies DESC,
    tm.production_year DESC;

### Explanation of the SQL Query:
1. **CTEs for Hierarchical Movie Relationships**: 
   - The `movie_hierarchy` CTE recursively fetches movies from the `aka_title` table based on their production year (2000 and later) and builds a hierarchy of linked movies.

2. **Counting Movies per Actor**:
   - The `actor_movie_counts` CTE counts distinct movies per actor (from `cast_info`) involved in the movies returned by the `movie_hierarchy`, filtering out actors who have appeared in more than five movies.

3. **Actor Details with Additional Information**:
   - The `actor_details` CTE retrieves actor names from `aka_name`, joining with previously calculated movie counts and gathering additional details from `person_info`, specifically for 'Bio'.

4. **Top Movies**:
   - The `top_movies` CTE selects the top movies from `movie_hierarchy` based on the production year but only retrieves movies within a depth of 2. It uses the `ROW_NUMBER()` window function to rank the movies.

5. **Final Selection**:
   - The final SELECT statement retrieves actor names, their additional information, top movie titles, and production years, filtering for actors who have counts greater than the average and ordering the results accordingly.

This query showcases various SQL semantics, including CTEs, window functions, correlated subqueries, outer joins, and complex filtering/logical conditions, making it rich and intricate.
