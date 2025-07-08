
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword
    FROM
        RankedTitles rt
    WHERE
        rt.title_rank <= 5
),
TitleWithActorInfo AS (
    SELECT
        tr.title_id,
        tr.title,
        tr.production_year,
        a.name AS actor_name,
        a.md5sum AS actor_md5
    FROM
        TopRankedTitles tr
    JOIN
        complete_cast cc ON tr.title_id = cc.movie_id
    JOIN
        aka_name a ON cc.subject_id = a.person_id
)
SELECT
    tw.title,
    tw.production_year,
    LISTAGG(DISTINCT tw.actor_name, ', ') WITHIN GROUP (ORDER BY tw.actor_name) AS actors,
    COUNT(DISTINCT tw.actor_md5) AS unique_actor_count
FROM
    TitleWithActorInfo tw
GROUP BY
    tw.title,
    tw.production_year
ORDER BY
    tw.production_year DESC;
