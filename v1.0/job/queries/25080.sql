
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank_keyword
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS number_of_actors,
        STRING_AGG(DISTINCT p.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name p ON ci.person_id = p.person_id
    GROUP BY
        ci.movie_id
),
MergedInfo AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        ar.number_of_actors,
        ar.actor_names,
        rt.keyword
    FROM
        RankedTitles rt
    JOIN
        ActorRoles ar ON rt.title_id = ar.movie_id
)
SELECT
    mi.id AS movie_info_id,
    mi.info AS additional_info,
    mi.note AS info_note,
    m.title,
    m.production_year,
    m.number_of_actors,
    m.actor_names,
    STRING_AGG(DISTINCT rt.keyword, ', ') AS keywords
FROM
    movie_info mi
JOIN
    MergedInfo m ON mi.movie_id = m.title_id
LEFT JOIN
    RankedTitles rt ON mi.movie_id = rt.title_id
WHERE
    mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%fun%')
GROUP BY
    mi.id, mi.info, mi.note, m.title, m.production_year, m.number_of_actors, m.actor_names
ORDER BY
    m.production_year DESC, m.number_of_actors DESC;
