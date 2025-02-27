WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000 AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        l.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1 AS level
    FROM
        movie_link l
    JOIN
        aka_title a ON l.linked_movie_id = a.id
    JOIN
        movie_hierarchy mh ON l.movie_id = mh.movie_id
    WHERE
        a.production_year >= 2000
)

SELECT
    h.title AS movie_title,
    h.production_year,
    h.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
FROM
    movie_hierarchy h
LEFT JOIN
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = h.movie_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = h.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
WHERE
    h.level = 0
GROUP BY
    h.title,
    h.production_year,
    h.level
ORDER BY
    h.production_year DESC,
    actor_count DESC
LIMIT 10;

This SQL query includes:

- A recursive CTE (`movie_hierarchy`) to gather data about movies and their linked sequels/spin-offs produced from the year 2000 onwards.
- Outer joins to include movies even if they don't have any associated cast members or production companies.
- Aggregation functions to count distinct actors and production companies for each movie.
- String aggregation to concatenate the names of the cast.
- A filtering predicate ensuring that only the movies themselves (level 0) are displayed in the ultimate result set, which is sorted by production year and actor count.
- The final output is limited to the top 10 results for performance benchmarking.
