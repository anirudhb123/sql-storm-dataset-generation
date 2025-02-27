WITH RECURSIVE referred_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        m.id,
        m.title,
        m.production_year,
        rm.level + 1
    FROM
        referred_movies rm
    JOIN
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        rm.level < 3 AND m.production_year >= 2000
),
actor_movies AS (
    SELECT
        ai.person_id,
        ai.movie_id,
        p.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id ORDER BY ai.nr_order) AS act_order
    FROM
        cast_info ai
    JOIN
        aka_name p ON ai.person_id = p.person_id
),
company_summary AS (
    SELECT
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS films_produced
    FROM
        movie_companies mc
    JOIN
        company_name cm ON mc.company_id = cm.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, cm.name, ct.kind
    HAVING
        COUNT(*) > 1
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    am.actor_name,
    am.act_order,
    cs.company_name,
    cs.company_type,
    cs.films_produced
FROM
    referred_movies rm
LEFT JOIN
    actor_movies am ON rm.movie_id = am.movie_id
LEFT JOIN
    company_summary cs ON rm.movie_id = cs.movie_id
WHERE
    (rm.production_year IS NOT NULL AND rm.production_year > 2010)
    OR (am.actor_name IS NOT NULL AND am.act_order < 5)
ORDER BY
    rm.production_year DESC, 
    am.act_order ASC,
    cs.films_produced DESC
LIMIT 100;
