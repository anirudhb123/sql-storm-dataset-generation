WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        c.person_id,
        COUNT(c.person_id) OVER (PARTITION BY c.movie_id) AS cast_count,
        COALESCE(a.name, 'Unknown') AS actor_name
    FROM
        cast_info c
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    SUM(cd.cast_count) AS total_cast,
    mc.companies,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')) AS awards_count
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE
    rm.rank <= 10
GROUP BY
    rm.movie_id, rm.title, rm.production_year, mc.companies
ORDER BY
    rm.production_year DESC, total_cast DESC;
