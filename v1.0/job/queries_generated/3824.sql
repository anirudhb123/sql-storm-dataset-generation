WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.title, t.production_year
),
HighActorMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM
        RankedMovies rm
    WHERE
        rm.rn <= 5
),
MovieDetails AS (
    SELECT
        hm.title,
        hm.production_year,
        COALESCE(k.keyword, 'N/A') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM
        HighActorMovies hm
    LEFT JOIN
        movie_keyword mk ON hm.title = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON hm.title = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
)
SELECT
    md.title,
    md.production_year,
    md.keyword,
    STRING_AGG(DISTINCT md.company_name, ', ') AS companies
FROM
    MovieDetails md
GROUP BY
    md.title, md.production_year, md.keyword
ORDER BY
    md.production_year DESC, COUNT(md.company_name) DESC
LIMIT 10;
