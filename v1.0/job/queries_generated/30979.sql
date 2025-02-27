WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT COALESCE(mk.keyword, 'N/A')) AS total_keywords,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS year_rank
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY
    mh.production_year DESC, mh.title ASC;

This query makes use of a recursive Common Table Expression (CTE) to retrieve a hierarchy of movies and their episodes. It joins multiple tables to calculate the total number of cast members and keywords associated with each movie, along with the names of the actors. There are additional constructs like `STRING_AGG` for concatenating actor names and `ROW_NUMBER` for ranking movies by production year. The `HAVING` clause ensures that only movies with more than one cast member are returned, and the final output is ordered by production year and title.
