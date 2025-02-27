WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title AS t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM
        cast_info AS c
    JOIN
        aka_name AS a ON c.person_id = a.person_id
    JOIN
        role_type AS r ON c.role_id = r.id
    GROUP BY
        c.movie_id, a.name, r.role
),
KeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword_count,
        ar.actor_name,
        ar.role_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        title AS t
    LEFT JOIN
        KeywordCounts AS k ON t.id = k.movie_id
    LEFT JOIN
        ActorRoles AS ar ON t.id = ar.movie_id
    WHERE
        t.production_year >= 2000
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    md.actor_name,
    md.role_name
FROM
    MovieDetails AS md
WHERE
    md.title_rank <= 5
ORDER BY
    md.production_year DESC, md.title;
