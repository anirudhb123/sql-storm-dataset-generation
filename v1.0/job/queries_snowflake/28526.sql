
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title) DESC, t.production_year DESC) AS title_rank
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
CastDetails AS (
    SELECT
        cc.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')')) AS full_cast,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM
        complete_cast cc
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        cc.movie_id
),
MovieCompanyDetails AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    cd.full_cast,
    cd.total_cast,
    mcd.production_companies,
    mcd.company_types
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN
    MovieCompanyDetails mcd ON rm.title_id = mcd.movie_id
WHERE
    rm.title_rank = 1
ORDER BY
    rm.production_year DESC, rm.title;
