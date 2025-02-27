
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        cn.country_code = 'USA'
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    cd.company_names,
    CASE
        WHEN rm.rn % 2 = 0 THEN 'Even Year'
        ELSE 'Odd Year'
    END AS year_type
FROM
    RankedMovies rm
LEFT JOIN
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC, rm.title;
