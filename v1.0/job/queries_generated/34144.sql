WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1
    FROM
        aka_title e
    INNER JOIN
        movie_hierarchy h ON e.episode_of_id = h.movie_id
),
ranked_movies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.level,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM
        movie_hierarchy m
),
movie_cast AS (
    SELECT
        mk.movie_id,
        a.name AS actor_name,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY a.name) AS actor_rank
    FROM
        movie_keyword mk
    JOIN
        cast_info ci ON mk.movie_id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rc ON ci.role_id = rc.id
),
company_info AS (
    SELECT
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cm ON mc.company_id = cm.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
final_results AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rc.actor_name,
        rc.role_name,
        ci.company_name,
        ci.company_type,
        rm.level,
        rm.rank_by_title,
        rc.actor_rank,
        COALESCE(rm.total_movies, 0) AS total_movies_year
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_cast rc ON rm.movie_id = rc.movie_id
    LEFT JOIN
        company_info ci ON rm.movie_id = ci.movie_id
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.role_name,
    f.company_name,
    f.company_type,
    f.level,
    f.rank_by_title,
    f.actor_rank,
    f.total_movies_year
FROM
    final_results f
WHERE
    (f.role_name IS NOT NULL AND f.actor_rank <= 5) OR
    (f.company_type IS NOT NULL AND f.company_name LIKE '%Studios%')
ORDER BY
    f.production_year DESC,
    f.title ASC;
