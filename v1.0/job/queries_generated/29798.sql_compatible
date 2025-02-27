
WITH recent_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(cc.subject_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    WHERE
        t.production_year >= 2020
    GROUP BY
        t.id, t.title, t.production_year
),
top_cast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id, ak.name
    HAVING
        COUNT(*) > 1
),
movies_with_actor_count AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.cast_count,
        COALESCE(tc.actor_name, 'Unknown') AS top_actor,
        COALESCE(tc.role_count, 0) AS top_actor_role_count
    FROM
        recent_movies rm
    LEFT JOIN
        top_cast tc ON rm.movie_id = tc.movie_id
)
SELECT
    mwac.title,
    mwac.production_year,
    mwac.cast_count,
    mwac.keywords,
    mwac.top_actor,
    mwac.top_actor_role_count
FROM
    movies_with_actor_count mwac
ORDER BY
    mwac.production_year DESC,
    mwac.cast_count DESC
LIMIT 10;
