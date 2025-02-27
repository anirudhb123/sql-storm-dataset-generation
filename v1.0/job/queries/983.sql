WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY ct.kind) AS company_rank
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_list
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id
),
KeywordDetails AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.company_name,
    cd.company_type,
    ar.unique_roles,
    ar.roles_list,
    kd.keywords
FROM
    RankedMovies rm
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN
    KeywordDetails kd ON rm.movie_id = kd.movie_id
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC,
    rm.title ASC;
