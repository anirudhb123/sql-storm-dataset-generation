WITH ranked_movies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_details AS (
    SELECT
        ci.movie_id,
        array_agg(an.name) AS actor_names,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY
        ci.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
movies_with_details AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_names,
        cd.unique_roles,
        mk.keyword
    FROM
        ranked_movies rm
    LEFT JOIN
        cast_details cd ON rm.movie_id = cd.movie_id
    LEFT JOIN
        movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.year_rank <= 5
)
SELECT
    m.title,
    m.production_year,
    COALESCE(m.actor_names[1], 'Unknown Actor') AS leading_actor,
    m.unique_roles,
    STRING_AGG(DISTINCT m.keyword, ', ') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.movie_id AND cc.status_id = 1) AS completed_cast_count
FROM
    movies_with_details m
GROUP BY
    m.movie_id, m.title, m.production_year, m.unique_roles
ORDER BY
    m.production_year DESC, m.title ASC;
