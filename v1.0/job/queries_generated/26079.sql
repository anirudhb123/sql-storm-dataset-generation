WITH RankedTitles AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
MovieCast AS (
    SELECT
        c.movie_id,
        p.name AS actor_name,
        p.gender,
        c.nr_order
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    WHERE
        c.nr_order < 5
),
DetailedMovieInfo AS (
    SELECT
        rt.movie_title,
        rt.production_year,
        mc.actor_name,
        mc.gender,
        rt.keyword,
        rt.title_rank
    FROM
        RankedTitles rt
    JOIN
        MovieCast mc ON rt.movie_id = mc.movie_id
)
SELECT
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS cast,
    COUNT(DISTINCT keyword) AS keyword_count
FROM
    DetailedMovieInfo
GROUP BY
    movie_title,
    production_year
ORDER BY
    production_year DESC,
    keyword_count DESC;
