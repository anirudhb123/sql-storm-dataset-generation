WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
    FROM
        title m
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvMovie'))
),
KeywordCount AS (
    SELECT
        m.movie_id,
        COUNT(k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        title m ON mk.movie_id = m.id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.movie_id
),
CompanyInfo AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mc.note IS NULL
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    GROUP_CONCAT(DISTINCT rm.actor_name ORDER BY rm.actor_rank) AS actors,
    kc.keyword_count,
    ci.company_name,
    ci.company_type
FROM
    RankedMovies rm
LEFT JOIN
    KeywordCount kc ON rm.movie_id = kc.movie_id
LEFT JOIN
    CompanyInfo ci ON rm.movie_id = ci.movie_id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, ci.company_name, ci.company_type
ORDER BY
    rm.production_year DESC, rm.title;
