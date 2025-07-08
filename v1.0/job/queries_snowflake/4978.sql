
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
CastWithRole AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.id) AS cast_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
MovieCompanyDetails AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(cwr.cast_count, 0) AS total_cast_count,
    COALESCE(mcd.companies, 'No Companies') AS associated_companies,
    COALESCE(mcd.company_types, 'No Types') AS associated_company_types,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords
FROM
    RankedMovies rm
LEFT JOIN
    CastWithRole cwr ON rm.title_id = cwr.movie_id AND cwr.role = 'Actor'
LEFT JOIN
    MovieCompanyDetails mcd ON rm.title_id = mcd.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE
    rm.year_rank <= 5
ORDER BY
    rm.production_year DESC, rm.title;
