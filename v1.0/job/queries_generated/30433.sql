WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ci.person_id,
        ct.kind AS role,
        0 AS level
    FROM
        cast_info ci
    JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE
        ci.nr_order = 1

    UNION ALL

    SELECT
        ci.person_id,
        ct.kind,
        ah.level + 1
    FROM
        cast_info ci
    JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN
        ActorHierarchy ah ON ci.movie_id = (
            SELECT
                movie_id
            FROM
                cast_info
            WHERE
                person_id = ah.person_id
            LIMIT 1
        )
    WHERE
        ci.nr_order = 1
),
MovieYearInfo AS (
    SELECT
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(COALESCE(mi.info::integer, 0)) AS average_rating
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN
        movie_info mi ON at.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        at.production_year
),
KeywordCount AS (
    SELECT
        at.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title at
    LEFT JOIN
        movie_keyword mk ON at.movie_id = mk.movie_id
    GROUP BY
        at.movie_id
)
SELECT
    ah.person_id,
    a.name AS actor_name,
    COALESCE(myi.actor_count, 0) AS total_actors,
    COALESCE(myi.average_rating, 'N/A') AS average_rating,
    COALESCE(kc.keyword_count, 0) AS total_keywords
FROM
    ActorHierarchy ah
JOIN
    aka_name a ON ah.person_id = a.person_id
LEFT JOIN
    MovieYearInfo myi ON myi.production_year = (
        SELECT
            DISTINCT at.production_year
        FROM
            aka_title at
        JOIN
            cast_info ci ON ci.movie_id = at.movie_id
        WHERE
            ci.person_id = ah.person_id
        LIMIT 1
    )
LEFT JOIN
    KeywordCount kc ON kc.movie_id = (
        SELECT
            DISTINCT ci.movie_id
        FROM
            cast_info ci
        WHERE
            ci.person_id = ah.person_id
        LIMIT 1
    )
ORDER BY
    ah.level, a.actor_name;
