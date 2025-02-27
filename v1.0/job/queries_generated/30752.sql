WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title AS m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT('Continuation of: ', mh.movie_title) AS movie_title,
        mh.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        movie_hierarchy AS mh ON ml.linked_movie_id = mh.movie_id
    JOIN
        aka_title AS m ON m.id = ml.movie_id
)

SELECT
    m.id AS movie_id,
    m.title,
    COUNT(DISTINCT c.person_id) AS total_cast,
    AVG(
        CASE 
            WHEN m.production_year IS NULL THEN NULL 
            ELSE EXTRACT(YEAR FROM CURRENT_DATE) - m.production_year 
        END
    ) AS average_movie_age,
    STRING_AGG(DISTINCT a.name, ', ') AS all_cast_names,
    MAX(i.info) AS latest_info_type,
    COALESCE(k.keyword, 'No Keywords') AS first_keyword
FROM
    movie_hierarchy AS m
LEFT OUTER JOIN
    complete_cast AS cc ON cc.movie_id = m.movie_id
LEFT JOIN
    cast_info AS c ON c.movie_id = m.movie_id
LEFT JOIN
    aka_name AS a ON a.person_id = c.person_id
LEFT JOIN
    movie_info AS i ON i.movie_id = m.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
LEFT JOIN
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN
    keyword AS k ON k.id = mk.keyword_id
WHERE
    m.level = 1
GROUP BY
    m.id,
    m.title,
    m.production_year,
    k.keyword
ORDER BY
    average_movie_age DESC,
    m.title
LIMIT 20;

This query performs the following:

1. **Recursive CTE (Common Table Expression)**: It creates a hierarchy of movies starting from movies released after 2000, allowing for a multi-level understanding of movie connections through links.

2. **Aggregate Functions**: It counts the total cast involved in each movie, calculates the average age of movies dynamically based on the current year, and aggregates actors' names into a single string.

3. **Joins**: The query uses outer joins to gather relevant data across various tables, ensuring that even movies without certain attributes (like keywords or casting information) are included.

4. **NULL Handling**: It includes logic that safely handles situations where certain fields might be NULL, such as using `COALESCE` to ensure a default value is provided for missing keywords.

5. **Filtering and Grouping**: The grouping is done based on movie ID and title while ensuring that only top-level movies in the hierarchy are selected.

6. **Dynamic Data Processing**: The use of the `EXTRACT` function to calculate the age of a movie dynamically as the current date changes adds a layer of temporal context to the cinema data.

7. **Ordering and Limiting**: Finally, it orders the results based on average movie age, giving priority to older movies in case of ties in the title.

Overall, the query showcases various SQL concepts while providing valuable insights into the movies released after 2000 and their connections.
