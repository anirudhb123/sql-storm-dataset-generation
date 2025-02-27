WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT(mp.title, ' (linked to: ', m.title, ')') AS title,
        m.production_year,
        depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy mp ON ml.movie_id = mp.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS num_cast_members,
    ARRAY_AGG(DISTINCT k.keyword) AS associated_keywords,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2010 AND 2018 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category,
    STRING_AGG(DISTINCT s.name, ', ') AS surnames
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    aka_name s ON ca.person_id = s.person_id
WHERE
    mh.depth < 3
GROUP BY
    mh.movie_id, mh.title, mh.production_year
ORDER BY
    num_cast_members DESC, mh.production_year ASC
LIMIT 100;

This query does the following:
- Defines a recursive CTE `movie_hierarchy` to build a hierarchy of movies linked through the `movie_link` table.
- Retrieves various details about each movie, including a count of distinct cast members and associated keywords.
- Categories movies based on their production year.
- Utilizes several joins, including outer joins.
- Applies string aggregation to compile surnames of cast members.
- Uses conditional logic with a `CASE` statement to create more meaningful categories for the movies.
- Orders by the number of cast members and production year to find the most popular movies while limiting the results to 100.

