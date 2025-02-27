WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming 1 corresponds to 'feature'

    UNION ALL

    SELECT
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link m ON m.movie_id = mh.movie_id
    JOIN
        aka_title at ON at.id = m.linked_movie_id
)

SELECT
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(ka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_actors,
    SUM(CASE WHEN p.gender IS NULL THEN 1 ELSE 0 END) AS unknown_gender_actors,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ka.name) AS actor_order
FROM
    MovieHierarchy m
LEFT JOIN
    cast_info c ON c.movie_id = m.movie_id
LEFT JOIN
    aka_name ka ON ka.person_id = c.person_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN
    movie_keyword mw ON mw.movie_id = m.movie_id
LEFT JOIN
    keyword kw ON kw.id = mw.keyword_id
LEFT JOIN
    name p ON p.id = c.person_id
WHERE
    m.level <= 2  -- Limit levels for performance
GROUP BY
    m.id, m.title, m.production_year, ka.name
HAVING
    COUNT(DISTINCT mc.company_id) > 1  -- Filter for movies with more than one production company
ORDER BY
    m.production_year DESC, 
    actor_order;

This SQL query uses various advanced constructs to create a comprehensive performance benchmarking scenario. It includes:

- A recursive Common Table Expression (CTE) to build a hierarchy of movies based on their links to other movies.
- Multiple joins to gather information about cast, production companies, and keywords.
- Aggregation and window functions to calculate data groups and orders.
- Conditional expressions (SUM with CASE) to count actors by gender and handle NULL values.
- String aggregation for keywords related to each movie.
- Filtering on the query to return only those movies that have more than one production company. 

This provides a detailed insight into movies and their associated attributes, showcasing performance across complex SQL operations.
