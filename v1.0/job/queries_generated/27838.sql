WITH movie_cast AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        p.id AS person_id,
        a.name AS actor_name,
        r.role AS role_name,
        CAST(m.production_year AS text) || ' - ' || a.name AS year_actor_role
    FROM
        aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE
        m.production_year >= 2000
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
movie_info_with_keywords AS (
    SELECT
        mc.movie_id,
        mc.title,
        mc.production_year,
        mc.actor_name,
        mc.role_name,
        mk.keywords
    FROM
        movie_cast mc
    LEFT JOIN movie_keywords mk ON mc.movie_id = mk.movie_id
),
final_result AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_name,
        role_name,
        keywords,
        COUNT(DISTINCT actor_name) OVER (PARTITION BY production_year) AS actors_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS title_rank
    FROM
        movie_info_with_keywords
)

SELECT
    movie_id,
    title,
    production_year,
    actor_name,
    role_name,
    keywords,
    actors_count,
    title_rank
FROM
    final_result
WHERE
    title_rank <= 5
ORDER BY
    production_year DESC, title;
