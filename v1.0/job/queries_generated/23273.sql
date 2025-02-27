WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(ci.id) OVER (PARTITION BY t.id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON ci.movie_id = t.id
    WHERE
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%feature%')
),
CastDetails AS (
    SELECT
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ci.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY t.production_year DESC) AS role_rank
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.id
    WHERE
        ak.name ILIKE '%Smith%'
),
CompanyMovieDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        COUNT(m.id) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        movie_info m ON m.movie_id = mc.movie_id AND m.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%award%')
),
FinalResults AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.cast_note,
        cmd.company_name,
        cmd.country_code,
        COALESCE(cd.role_rank, 0) AS actor_role_rank,
        COALESCE(rm.cast_count, 0) AS total_cast,
        cmd.company_count
    FROM
        RankedMovies rm
    LEFT JOIN
        CastDetails cd ON rm.movie_id = cd.movie_title
    LEFT JOIN
        CompanyMovieDetails cmd ON rm.movie_id = cmd.movie_id
)
SELECT
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.cast_note,
    fr.company_name,
    fr.country_code,
    fr.actor_role_rank,
    fr.total_cast,
    fr.company_count
FROM
    FinalResults fr
WHERE
    fr.production_year BETWEEN 2000 AND 2023
    AND (fr.total_cast > 0 OR fr.company_count IS NULL)
ORDER BY
    fr.production_year DESC, fr.actor_name ASC
LIMIT 50;

