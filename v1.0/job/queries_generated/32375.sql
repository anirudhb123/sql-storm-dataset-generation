WITH RECURSIVE movie_hierarchy AS (
    SELECT
        pt.id AS movie_id,
        pt.title,
        0 AS level,
        CAST(pt.title AS VARCHAR(255)) AS path
    FROM
        aka_title pt
    WHERE
        pt.kind_id = 1  -- Assuming kind_id '1' corresponds to a specific movie type
    UNION ALL
    SELECT
        mt.linked_movie_id,
        mt.title,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', mt.title)
    FROM
        movie_link ml
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3  -- Limit to a hierarchy of 3 levels
),
cast_and_info AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) ELSE NULL END) AS avg_person_info_length  -- Assuming 1 corresponds to a certain info type
    FROM
        cast_info ci
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    GROUP BY
        ci.movie_id
),
keyword_info AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    COALESCE(cai.total_cast, 0) AS total_cast,
    COALESCE(cai.avg_person_info_length, 0) AS avg_person_info_length,
    COALESCE(ki.keywords, '') AS keywords,
    mh.path
FROM
    movie_hierarchy mh
LEFT JOIN cast_and_info cai ON mh.movie_id = cai.movie_id
LEFT JOIN keyword_info ki ON mh.movie_id = ki.movie_id
ORDER BY
    mh.level,
    mh.title;

### Explanation of the Query:

1. **Recursive CTE (`movie_hierarchy`)**: This CTE builds a hierarchy of movies based on links between them. It starts from the base movies (kind_id = 1) and retrieves linked movies, building a path that shows the relationship up to three levels deep.

2. **Aggregated Cast Information (`cast_and_info`)**: This CTE counts the total number of distinct cast members for each movie and calculates the average length of personal information (based on a specific info type ID).

3. **Keyword Aggregation (`keyword_info`)**: This CTE gathers keywords associated with each movie into a concatenated string.

4. **Final Selection**: The main query selects from the `movie_hierarchy`, joining both `cast_and_info` and `keyword_info` CTEs using left joins. It ensures that any movie without cast or keywords will still appear in the results, substituting NULLs with default values.

5. **Ordering the Results**: It orders the results first by the level of hierarchy and then by the movie title, providing a clear and structured output.

The query highlights the use of complex SQL constructs like recursive common table expressions, aggregation, and string functions, all while maintaining performance through thoughtful left joins.
