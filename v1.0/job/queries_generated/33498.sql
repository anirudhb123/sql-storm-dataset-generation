WITH RECURSIVE actor_hierarchy AS (
    SELECT
        ci.person_id,
        COUNT(*) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(*) DESC) AS rank
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
),
popular_titles AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        aka_title at
    JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.title, at.production_year
    HAVING
        COUNT(DISTINCT ci.person_id) > 5
),
actor_names AS (
    SELECT
        ak.name,
        ah.role_count,
        ah.rank
    FROM
        aka_name ak
    JOIN
        actor_hierarchy ah ON ak.person_id = ah.person_id
    WHERE
        ah.rank <= 10
),
movie_ratings AS (
    SELECT
        mt.movie_id,
        AVG(mv.info::float) AS avg_rating
    FROM
        movie_info mv
    JOIN
        movie_info_idx mi ON mv.movie_id = mi.movie_id
    WHERE
        mv.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        mt.movie_id
)
SELECT
    at.title,
    at.production_year,
    an.name AS top_actor,
    an.role_count,
    mr.avg_rating
FROM
    popular_titles at
LEFT JOIN
    actor_names an ON an.rank = 1
LEFT JOIN
    movie_ratings mr ON at.movie_id = mr.movie_id
WHERE
    mr.avg_rating IS NOT NULL AND
    at.production_year > 2000
ORDER BY
    mr.avg_rating DESC,
    at.production_year DESC;
