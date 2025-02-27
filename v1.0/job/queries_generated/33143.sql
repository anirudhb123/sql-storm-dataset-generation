WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS movie_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies
    FROM
        MovieHierarchy mh
),
CastRoles AS (
    SELECT
        ci.movie_id,
        ci.role_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, ci.role_id, rt.role
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, cn.name, ct.kind
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.movie_rank,
    rm.total_movies,
    COALESCE(cr.role, 'Unknown') AS role_name,
    COALESCE(cr.role_count, 0) AS number_of_roles,
    cd.company_name,
    cd.company_type,
    COALESCE(cd.company_count, 0) AS total_companies
FROM
    RankedMovies rm
LEFT JOIN
    CastRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY
    rm.production_year DESC, rm.movie_rank;
