WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT
    ak.name AS actor_name,
    k.keyword AS movie_keyword,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.movie_id) AS total_movies_casted,
    AVG(EXTRACT(EPOCH FROM (date_part('year', now()) - mh.production_year))) AS avg_years_since_release,
    STRING_AGG(DISTINCT COALESCE(ca.role_id::text, 'N/A'), ', ') AS roles,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS role_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    role_type ca ON ca.id = ci.role_id
WHERE
    mh.production_year <= EXTRACT(YEAR FROM now()) -- we want movies up to the current year
    AND ak.name IS NOT NULL -- filtering out potential NULL actor names
GROUP BY
    ak.name, k.keyword, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT ci.movie_id) > 1 -- filter for actors in more than one movie
ORDER BY
    avg_years_since_release DESC,
    total_movies_casted DESC;
