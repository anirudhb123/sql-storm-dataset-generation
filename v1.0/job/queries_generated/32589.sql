WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000  -- example filter for recent movies

    UNION ALL

    SELECT
        ml.linked_movie_id,
        al.title,
        al.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title al ON ml.linked_movie_id = al.id
    WHERE
        mh.level < 3  -- limit depth of recursion
)
SELECT
    COALESCE(ca.name, cn.name, 'Unknown') AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(pi.rating) AS avg_rating
FROM
    MovieHierarchy m
LEFT JOIN
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN
    aka_name ca ON ci.person_id = ca.person_id
LEFT JOIN
    char_name cn ON ci.person_id = cn.imdb_id
LEFT JOIN
    movie_company mc ON m.movie_id = mc.movie_id
LEFT JOIN
    movie_keyword k ON m.movie_id = k.movie_id
LEFT JOIN
    (SELECT
         movie_id,
         AVG(CASE WHEN info_type_id = 1 THEN CAST(info AS FLOAT) END) AS rating
     FROM
         movie_info
     GROUP BY
         movie_id) pi ON m.movie_id = pi.movie_id
WHERE
    m.level > 1  -- filter for movies that have links
GROUP BY
    actor_name, m.title, m.production_year
ORDER BY
    m.production_year DESC, actor_name;
