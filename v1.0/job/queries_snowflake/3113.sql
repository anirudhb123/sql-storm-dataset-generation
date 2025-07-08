
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCounts AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.actor_count, 0) AS number_of_actors,
    COALESCE(mc.companies, 'None') AS production_companies,
    COALESCE(mi.info_details, 'No information available') AS additional_info
FROM
    RankedMovies r
LEFT JOIN
    ActorCounts ac ON r.movie_id = ac.movie_id
LEFT JOIN
    MovieCompanies mc ON r.movie_id = mc.movie_id
LEFT JOIN
    MovieInfo mi ON r.movie_id = mi.movie_id
WHERE
    r.rank <= 5
ORDER BY
    r.production_year DESC, r.title;
