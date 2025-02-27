WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM
        aka_title t
        JOIN title m ON t.movie_id = m.id
    WHERE
        m.production_year > 2000

    UNION ALL

    SELECT
        mh.movie_id,
        CONCAT(mh.title, ' (Sequel)') AS title,
        mh.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
        JOIN movie_link ml ON mh.movie_id = ml.movie_id
        JOIN title m ON ml.linked_movie_id = m.id
    WHERE
        mh.level < 3  -- Limit recursion to a depth of 3
),

MovieDetails AS (
    SELECT
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS actors
    FROM
        MovieHierarchy mh
        LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
        LEFT JOIN aka_name a ON ci.person_id = a.person_id
        LEFT JOIN role_type r ON ci.role_id = r.id
    GROUP BY
        mh.title, mh.production_year
),

CompanyInfo AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM
        movie_companies mt
        JOIN company_name cn ON mt.company_id = cn.id
    GROUP BY
        mt.movie_id
),

FinalResult AS (
    SELECT
        md.title,
        md.production_year,
        md.actor_count,
        md.actors,
        ci.companies
    FROM
        MovieDetails md
        LEFT JOIN CompanyInfo ci ON md.movie_id = ci.movie_id
    ORDER BY
        md.production_year DESC,
        md.actor_count DESC
)

SELECT *
FROM
    FinalResult
WHERE
    actor_count IS NOT NULL
    AND production_year IS NOT NULL
    AND (actors IS NOT NULL OR companies IS NOT NULL)
    AND actor_count > 5;  -- Filter for movies with more than 5 actors
