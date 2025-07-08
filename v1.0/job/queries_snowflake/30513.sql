
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastWithRoles AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
MoviesWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id,
        m.title
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM
        movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'No Actors') AS actor_name,
    COALESCE(cwr.role, 'Unknown Role') AS role,
    mwk.keywords,
    COALESCE(mcom.companies, 'No Companies') AS companies,
    mh.level
FROM
    MovieHierarchy mh
LEFT JOIN
    CastWithRoles cwr ON mh.movie_id = cwr.movie_id AND cwr.role_order = 1
LEFT JOIN
    MoviesWithKeywords mwk ON mh.movie_id = mwk.movie_id
LEFT JOIN
    MovieCompanies mcom ON mh.movie_id = mcom.movie_id
ORDER BY
    mh.production_year DESC,
    mh.level ASC,
    mh.title;
