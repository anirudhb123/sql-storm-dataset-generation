WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
movie_actors AS (
    SELECT
        c.movie_id,
        a.name,
        COUNT(*) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id, a.name
),
expanded_movie_info AS (
    SELECT
        m.movie_id,
        COALESCE(mi.info, 'No Info Available') AS info,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM
        movie_info m
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        M.info_type_id IS NOT NULL
),
rich_cast AS (
    SELECT
        m.movie_id,
        m.title,
        a.name AS actor_name,
        ct.kind AS cast_type,
        CASE
            WHEN ct.kind <> 'Other' THEN 1
            ELSE 0
        END AS is_signed
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        comp_cast_type ct ON cd.person_role_id = ct.id
)

SELECT
    m.title,
    m.production_year,
    rc.actor_name,
    COUNT(DISTINCT rc.cast_type) AS distinct_roles,
    CASE
        WHEN SUM(rc.is_signed) > 0 THEN 'Signed'
        ELSE 'Unsigned'
    END AS signing_status,
    COALESCE(e.info, 'N/A') AS movie_info,
    grouped.year_rank
FROM
    rich_cast rc
JOIN
    ranked_titles grouped ON rc.movie_id = grouped.title_id
LEFT JOIN
    expanded_movie_info e ON rc.movie_id = e.movie_id
WHERE
    rc.actor_name IS NOT NULL AND
    grouped.rank_per_year > 3
GROUP BY
    m.title,
    m.production_year,
    rc.actor_name,
    e.info,
    grouped.year_rank
ORDER BY
    grouped.production_year DESC,
    distinct_roles DESC;
