
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_per_year
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
),
FilmStats AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_assigned
    FROM
        complete_cast m
    LEFT JOIN
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        m.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
KeywordAssociations AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    fs.cast_count,
    COALESCE(fs.avg_role_assigned, 0) AS avg_role,
    cd.company_name,
    cd.company_type,
    ka.keywords
FROM
    RankedMovies rm
LEFT JOIN
    FilmStats fs ON rm.movie_id = fs.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    KeywordAssociations ka ON rm.movie_id = ka.movie_id
WHERE
    rm.rank_per_year <= 5
ORDER BY
    rm.production_year DESC,
    rm.title ASC;
