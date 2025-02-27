WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id 
    WHERE 
        t.kind_id = 1 -- assuming 1 for feature films

    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        aka_title t ON m.id = t.id
    WHERE 
        t.kind_id = 1
)

SELECT
    c.person_id,
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS movies_count,
    AVG(mi2.info LIKE '%Award%'::text) AS avg_award_win,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY COUNT(DISTINCT ch.movie_id) DESC) AS actor_rank
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
LEFT JOIN
    movie_hierarchy ch ON c.movie_id = ch.movie_id
LEFT JOIN
    title t ON c.movie_id = t.id
WHERE
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND (mi.info IS NULL OR mi.info <> '') -- Excluding NULL values from info
GROUP BY
    c.person_id,
    a.name
HAVING
    COUNT(DISTINCT ch.movie_id) > 3
ORDER BY
    movies_count DESC, avg_award_win DESC;

### Explanation of the SQL query:

1. **CTE - Recursive Movie Hierarchy**: 
   - This part builds a recursive Common Table Expression (CTE) to represent a hierarchical structure of movies based on their links. Starting from feature films (assuming `kind_id = 1`), it finds related titles.

2. **Main Select Statement**:
   - Selects the `person_id` and `actor_name`, aggregates data about movies each actor has participated in, counts distinct movies, calculates the average number of winning awards (checking if the info contains the word 'Award'), and aggregates the titles into a single string.
   - Uses a `LEFT JOIN` to include even those movies for which there might not be award information.
   - Filters out records with NULL names or pre-2000 productions and excludes NULL info from award results.

3. **Grouping and Ranking**:
   - Groups results by `person_id` and actor name. It ensures that only actors who have worked in more than 3 distinct linked movies based on the `HAVING` clause will be presented in the final results.
   - Introduces a ranking for actors based on the number of movies they've participated in, using `ROW_NUMBER()`.

4. **Ordering**: 
   - Results are ordered primarily by the count of participating movies and secondarily by average award-winning status.

The complexity arises from the combination of recursive queries, multiple joins, aggregate functions, partitioning, and conditional predicates—all essential for performance benchmarking in an extensive database schema like the one defined.
