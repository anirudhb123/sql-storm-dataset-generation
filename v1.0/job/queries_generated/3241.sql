WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
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
    rm.actor_count,
    cs.company_count,
    cs.company_names,
    mk.keyword_count
FROM
    RankedMovies rm
LEFT JOIN
    CompanyStats cs ON rm.title = cs.movie_id
LEFT JOIN
    MovieKeywords mk ON rm.title = mk.movie_id
WHERE
    rm.rank <= 10
    AND (mk.keyword_count IS NULL OR mk.keyword_count > 5)
ORDER BY
    rm.production_year DESC, rm.actor_count DESC;
