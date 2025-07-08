
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
Actors AS (
    SELECT
        ak.name AS actor_name,
        ak.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    WHERE
        ak.name IS NOT NULL
),
TitleWithActors AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        a.actor_name,
        a.role_order
    FROM
        RankedTitles rt
    LEFT JOIN
        Actors a ON rt.title_id = a.movie_id
),
FinalResults AS (
    SELECT
        tw.title,
        tw.production_year,
        LISTAGG(tw.actor_name, ', ' ) WITHIN GROUP (ORDER BY tw.role_order) AS cast_names,
        COUNT(DISTINCT tw.actor_name) AS actor_count
    FROM
        TitleWithActors tw
    GROUP BY
        tw.title, tw.production_year
)
SELECT
    fr.title,
    fr.production_year,
    fr.cast_names,
    fr.actor_count
FROM
    FinalResults fr
WHERE
    fr.actor_count > 0
ORDER BY
    fr.production_year DESC, fr.title;
