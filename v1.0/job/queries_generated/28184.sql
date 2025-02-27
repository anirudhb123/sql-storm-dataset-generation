WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
MovieCast AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT rc.role, ', ') AS roles
    FROM
        complete_cast cc
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type rc ON ci.role_id = rc.id
    GROUP BY
        mc.movie_id
),
FinalResults AS (
    SELECT
        rt.title,
        rt.production_year,
        mc.actors,
        mc.roles,
        rt.keyword,
        rt.rank
    FROM
        RankedTitles rt
    LEFT JOIN
        MovieCast mc ON rt.title_id = mc.movie_id
    WHERE
        rt.rank = 1
)
SELECT
    title,
    production_year,
    actors,
    roles,
    keyword
FROM
    FinalResults
ORDER BY
    production_year DESC,
    title;
