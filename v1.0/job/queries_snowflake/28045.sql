WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM
        title t
    WHERE
        t.production_year >= 2000
),
MovieKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
TopActors AS (
    SELECT
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        a.name
    HAVING
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        mkc.keyword_count,
        ta.actor_name
    FROM
        RankedTitles rt
    LEFT JOIN
        MovieKeywordCounts mkc ON rt.title_id = mkc.movie_id
    LEFT JOIN
        cast_info ci ON rt.title_id = ci.movie_id
    LEFT JOIN
        TopActors ta ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = ta.actor_name LIMIT 1)
)
SELECT
    md.title,
    md.production_year,
    COALESCE(md.keyword_count, 0) AS keyword_count,
    COUNT(DISTINCT md.actor_name) AS actor_count
FROM
    MovieDetails md
GROUP BY
    md.title,
    md.production_year,
    md.keyword_count
ORDER BY
    md.production_year DESC,
    md.title;
