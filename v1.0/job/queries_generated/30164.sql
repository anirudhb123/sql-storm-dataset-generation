WITH RECURSIVE MovieHierarchy AS (
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
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON m.id = ml.linked_movie_id
)
SELECT
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    COALESCE(cast.main_actor, 'Unknown') AS main_actor,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(p.info::numeric) AS avg_person_age,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM
    MovieHierarchy m
LEFT JOIN
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN (
    SELECT 
        c.movie_id,
        an.name AS main_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    WHERE 
        ci.nr_order = 1
) cast ON cast.movie_id = m.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN
    person_info p ON p.person_id = an.person_id AND p.info_type_id = 1
WHERE
    m.level <= 2
GROUP BY
    m.id, m.title, m.production_year, cast.main_actor
ORDER BY
    m.production_year DESC, keyword_count DESC
LIMIT 50;

This SQL query performs the following actions:

1. Establishes a recursive Common Table Expression (CTE) to form a hierarchy of movies, starting from those produced in the year 2000 or later.
2. Joins various tables, including `complete_cast`, `cast_info`, and `aka_name`, to obtain the main actor's name.
3. Counts distinct keywords associated with each movie.
4. Averages the ages of the individuals related to the movie from the `person_info` table.
5. Gathers distinct company names associated with each movie.
6. Groups the results by movie ID, title, and other relevant fields, with ordering by production year and keyword count.
7. Limits the final output to 50 rows for performance benchmarking.
