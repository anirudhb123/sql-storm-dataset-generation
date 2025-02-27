WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_with_roles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),

keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),

filtered_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(k.total_keywords, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mh.title) AS movie_rank
    FROM
        movie_hierarchy mh
    LEFT JOIN
        keyword_count k ON mh.movie_id = k.movie_id
)

SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keyword_count,
    STRING_AGG(a.actor_name || ' (' || cr.role_name || ')', ', ') AS cast_info,
    MAX(cr.role_rank) AS max_role_rank
FROM
    filtered_movies fm
LEFT JOIN
    cast_with_roles cr ON fm.movie_id = cr.movie_id
GROUP BY
    fm.movie_id, fm.title, fm.production_year, fm.keyword_count
HAVING
    fm.keyword_count > 3 AND MAX(cr.role_rank) <= 3
ORDER BY
    fm.keyword_count DESC, fm.production_year DESC
LIMIT 10;
