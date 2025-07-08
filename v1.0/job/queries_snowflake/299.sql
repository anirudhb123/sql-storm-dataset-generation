
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_within_year
    FROM
        aka_title m
    LEFT JOIN
        cast_info ca ON m.id = ca.movie_id
    GROUP BY
        m.id, m.title, m.production_year
),
HighlightedActors AS (
    SELECT
        a.name,
        ca.movie_id,
        ca.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_position
    FROM
        aka_name a
    JOIN
        cast_info ca ON a.person_id = ca.person_id
    WHERE
        a.name IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.country_code IS NOT NULL
)
SELECT
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    COALESCE(COUNT(DISTINCT ha.actor_position), 0) AS total_actors,
    LISTAGG(DISTINCT ha.name, ', ') AS actor_names,
    COUNT(DISTINCT cd.company_name) AS total_companies,
    LISTAGG(DISTINCT cd.company_type, ', ') AS company_types
FROM
    RankedMovies rm
LEFT JOIN
    HighlightedActors ha ON rm.movie_id = ha.movie_id
LEFT JOIN
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE
    rm.rank_within_year <= 3
GROUP BY
    rm.movie_id, rm.movie_title, rm.production_year
ORDER BY
    rm.production_year DESC, total_actors DESC;
