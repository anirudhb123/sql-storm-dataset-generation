
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
SelectedMovies AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        kc.kind AS kind_name
    FROM
        RankedTitles rt
    JOIN
        kind_type kc ON rt.kind_id = kc.id
    WHERE
        rt.rank <= 10  
),
CastWithNames AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id
    FROM
        cast_info ci
    INNER JOIN
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT
    sm.title,
    sm.production_year,
    sm.kind_name,
    LISTAGG(cn.actor_name, ', ') WITHIN GROUP (ORDER BY cn.actor_name) AS actors
FROM
    SelectedMovies sm
LEFT JOIN
    CastWithNames cn ON sm.title_id = cn.movie_id
GROUP BY
    sm.title_id,
    sm.title,
    sm.production_year,
    sm.kind_name
ORDER BY
    sm.production_year DESC,
    sm.kind_name,
    sm.title;
