WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year BETWEEN 1990 AND 1995
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title a ON ml.linked_movie_id = a.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_roles AS (
    SELECT
        ci.movie_id,
        r.role AS role_name,
        COUNT(ci.person_id) AS num_cast
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id, r.role
),
movie_details AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        cr.role_name,
        cr.num_cast,
        COALESCE(CAST(mi.info AS VARCHAR), 'No Info') AS movie_info,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cr.num_cast DESC) AS role_rank
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_roles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.title,
    md.production_year,
    md.role_name,
    md.num_cast,
    md.movie_info,
    md.keyword
FROM
    movie_details md
WHERE
    md.role_rank = 1 
    AND (md.production_year IS NULL OR md.production_year >= 1990)
ORDER BY
    md.production_year DESC, 
    md.num_cast DESC
LIMIT 100;
