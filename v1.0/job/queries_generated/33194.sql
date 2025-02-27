WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS depth
    FROM aka_title m
    WHERE m.kind_id = 1 -- Assuming 1 corresponds to movies

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)
,
top_movies AS (
    SELECT mh.title, mh.production_year,
           COUNT(DISTINCT ci.person_id) AS num_actors,
           RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM movie_hierarchy mh
    JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY mh.title, mh.production_year
    HAVING COUNT(DISTINCT ci.person_id) > 5
),
high_rating_movies AS (
    SELECT mt.title, mi.info AS rating
    FROM top_movies mt
    JOIN movie_info mi ON mt.movie_id = mi.movie_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT DISTINCT co.name AS company_name,
       m.title AS movie_title,
       mw.rating,
       COUNT(DISTINCT ci.person_id) AS total_actors,
       STRING_AGG(DISTINCT n.name, ', ') AS actor_names
FROM high_rating_movies mw
JOIN movie_companies mc ON mw.movie_id = mc.movie_id
JOIN company_name co ON mc.company_id = co.id
JOIN complete_cast cc ON mw.movie_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN aka_name n ON ci.person_id = n.person_id
WHERE co.country_code = 'USA'
GROUP BY co.name, m.title, mw.rating
HAVING COUNT(DISTINCT ci.person_id) > 10
ORDER BY mw.rating DESC, total_actors DESC;

### Explanation

1. **Recursive CTE (movie_hierarchy)**: This CTE builds a hierarchy of movies linked together, allowing us to traverse linked movies.

2. **Top Movies (top_movies)**: This CTE identifies the top movies by the count of distinct actors (more than 5) working on them, ranking them.

3. **High Rating Movies (high_rating_movies)**: Retrieves the titles of top movies with their associated ratings from the `movie_info` table, focusing on those that have a specific rating type.

4. **Main Query**: 
   - Joins `high_rating_movies` with `movie_companies` and `company_name` to retrieve information about companies associated with these movies, filtering for companies based in the USA.
   - Utilizes `LEFT JOIN` to include actor names from `aka_name`, even if not all cast members have an associated `aka_name`.
   - Filters and groups results to show only those movies with more than 10 actors, aggregates actors' names, and orders the results by rating and total actors.

This SQL query provides a complex look into the connection between movies, their ratings, and the companies involved, making it suitable for performance benchmarking against the schema described.
