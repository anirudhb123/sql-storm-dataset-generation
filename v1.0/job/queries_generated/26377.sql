WITH MovieRoleCounts AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS role_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_names
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title
),
PopularKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mrc.movie_id,
    mrc.movie_title,
    mrc.role_count,
    mrc.cast_names,
    pk.keywords
FROM
    MovieRoleCounts mrc
LEFT JOIN
    PopularKeywords pk ON mrc.movie_id = pk.movie_id
ORDER BY
    mrc.role_count DESC, mrc.movie_title;
