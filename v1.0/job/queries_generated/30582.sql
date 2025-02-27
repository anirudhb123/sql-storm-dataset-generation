WITH RECURSIVE MovieHierarchy AS (
    SELECT
        title.id AS movie_id,
        title.title,
        title.production_year,
        1 AS depth
    FROM
        title
    WHERE
        title.production_year >= 2000

    UNION ALL

    SELECT
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM
        movie_link m
    JOIN
        title t ON m.linked_movie_id = t.id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    WHERE
        mh.depth < 3  -- Limit depth to prevent excessive recursion
)

SELECT
    a.id AS person_id,
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies_list,
    AVG(CASE WHEN t.production_year < 2010 THEN 1 ELSE NULL END) AS avg_movies_pre_2010,
    SUM(CASE 
        WHEN c.note IS NOT NULL AND c.note != '' THEN 1 
        ELSE 0 
    END) AS note_count,
    COALESCE(b.company_name, 'Unknown Company') AS producing_company,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY movies_count DESC) AS rank_within_actor
FROM
    aka_name a
LEFT JOIN
    cast_info c ON a.person_id = c.person_id
LEFT JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name b ON mc.company_id = b.id
LEFT JOIN
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND a.name != ''
GROUP BY
    a.id, a.name, b.company_name
HAVING
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY
    movies_count DESC, actor_name;

### Explanation:
1. **Common Table Expression (CTE):**
   - A recursive CTE named `MovieHierarchy` is created to track movies linked to each other, allowing us to analyze the hierarchy of movies produced since 2000 up to a depth of 3.

2. **Select Clause:**
   - The query fetches a list of actors along with additional metrics, including the count of movies they appeared in, a concatenated list of those movie titles, and metrics based on production years.
   - Uses conditional aggregation and string functions for better insights.

3. **Joins:**
   - Several outer joins link the `aka_name`, `cast_info`, `title`, `movie_companies`, `company_name`, and the recursive CTE together.

4. **Conditions:**
   - Ensures valid names are included, and checks if the actor has appeared in more than 5 movies with a `HAVING` clause.

5. **Ranking:**
   - Uses a window function to provide a ranking within each actor based on the number of movies they appeared in.

This query provides a rich analysis of actors in relation to the films they have been part of, their associated production companies, and the hierarchy of movie links.
