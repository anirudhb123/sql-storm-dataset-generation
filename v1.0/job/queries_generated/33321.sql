WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM
        movie_link AS ml
    JOIN
        title AS m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),
CastRoles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG DISTINCT(CONCAT(p.name, ' as ', r.role)) AS cast_details
    FROM
        cast_info AS c
    JOIN
        role_type AS r ON c.role_id = r.id
    JOIN
        aka_name AS p ON c.person_id = p.person_id
    GROUP BY
        c.movie_id
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies AS mc
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(cr.cast_details, 'No Cast') AS cast_details,
    COALESCE(cs.company_count, 0) AS company_count,
    COALESCE(cs.company_names, 'No Companies') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_within_year,
    LEAD(mh.title) OVER (ORDER BY mh.production_year) AS next_movie_title
FROM
    MovieHierarchy AS mh
LEFT JOIN
    CastRoles AS cr ON mh.movie_id = cr.movie_id
LEFT JOIN
    CompanyStats AS cs ON mh.movie_id = cs.movie_id
WHERE
    (mh.production_year = 2022 OR mh.production_year IS NULL)
ORDER BY
    mh.production_year DESC, mh.title;
