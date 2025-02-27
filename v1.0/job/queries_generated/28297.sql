WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM
        title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS main_keyword
    FROM
        title m
        JOIN movie_keyword mk ON m.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.phonetic_code IS NOT NULL
),
ActorDetails AS (
    SELECT
        a.person_id,
        ak.name AS actor_name,
        c.movie_id,
        COUNT(c.id) AS total_movies
    FROM
        cast_info c
        JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        a.person_id, ak.name, c.movie_id
),
PopularActors AS (
    SELECT
        actor_name,
        COUNT(total_movies) AS movie_count
    FROM
        ActorDetails
    GROUP BY
        actor_name
    HAVING COUNT(total_movies) > 5
)
SELECT
    rt.title_id,
    rt.title,
    rt.production_year,
    md.movie_title,
    md.main_keyword,
    pa.actor_name,
    pa.movie_count
FROM
    RankedTitles rt
    LEFT JOIN MovieDetails md ON rt.title_id = md.movie_id
    LEFT JOIN PopularActors pa ON md.movie_title = pa.actor_name
WHERE
    rt.rn BETWEEN 1 AND 10
ORDER BY
    rt.production_year DESC, rt.title;
