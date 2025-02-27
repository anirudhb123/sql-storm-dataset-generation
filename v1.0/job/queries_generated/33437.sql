WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    AVG(pi.info || ' : ' || pi.note) FILTER (WHERE pi.info IS NOT NULL AND pi.note IS NOT NULL) AS avg_info_note,
    CASE
        WHEN COUNT(DISTINCT ci.person_id) > 10 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ci.person_id) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%actor%')
GROUP BY
    mh.movie_id, mh.title, mh.production_year, k.keyword
ORDER BY
    mh.production_year DESC,
    num_cast_members DESC
LIMIT 50;

This query generates a performance benchmark by leveraging:

1. A recursive Common Table Expression (CTE) to build a movie hierarchy based on movie links.
2. Multiple LEFT JOINs to aggregate keywords, cast member information, and related person info.
3. COALESCE to handle possible NULL values for keywords.
4. A filtered AVG calculation with a CASE statement to categorize the size of the cast based on the number of cast members.
5. GROUP BY to summarize data, and ORDER BY for a ranked output.
