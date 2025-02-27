WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title ASC) AS year_rank
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
actor_roles AS (
    SELECT
        a.id AS actor_id,
        a.name,
        c.movie_id,
        CASE
            WHEN ci.role_id IS NOT NULL THEN r.role
            ELSE 'Unknown Role'
        END AS role_name
    FROM
        aka_name a
    LEFT JOIN (
        SELECT DISTINCT
            ci.person_id,
            ci.movie_id,
            ci.role_id
        FROM
            cast_info ci
        WHERE
            ci.nr_order IS NOT NULL
    ) AS ci ON a.person_id = ci.person_id
    LEFT JOIN role_type r ON ci.role_id = r.id
),
company_information AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE
        cn.country_code IS NOT NULL
        AND cn.name IS NOT NULL
    GROUP BY
        mc.movie_id
),
movie_details AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_id,
        ar.name AS actor_name,
        ar.role_name,
        ci.company_names,
        ci.company_count
    FROM
        ranked_movies rm
    LEFT JOIN actor_roles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN company_information ci ON rm.movie_id = ci.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.actor_name, 'No Actors') AS actor_name,
    COALESCE(md.role_name, 'No Role Assigned') AS role_name,
    COALESCE(md.company_names, 'No Companies') AS company_names,
    md.company_count,
    CASE
        WHEN md.production_year IS NOT NULL THEN md.production_year
        ELSE (SELECT MAX(production_year) FROM aka_title)
    END AS fallback_year
FROM
    movie_details md
WHERE
    md.year_rank <= 5
    OR md.company_count > 3
ORDER BY
    md.production_year DESC,
    md.title ASC
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;
