WITH RECURSIVE MovieHierachy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming 1 represents feature films

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.movie_id = mt.id
    JOIN
        MovieHierachy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mv.movie_title,
    mv.production_year,
    COALESCE(ka.name, 'Unknown') AS aka_name,
    c.role_id,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count,  -- Assuming info_type_id 1 represents awards
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM
    MovieHierachy mv
LEFT JOIN
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN
    aka_name ka ON c.person_id = ka.person_id
LEFT JOIN
    movie_info mi ON mv.movie_id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mv.production_year BETWEEN 2000 AND 2023  -- Filtering for recent movies
GROUP BY
    mv.movie_id, mv.movie_title, mv.production_year, ka.name, c.role_id
ORDER BY
    mv.production_year DESC, total_cast DESC;
