WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword tk ON mk.keyword_id = tk.id
    WHERE
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        ci.movie_id,
        ci.role_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        aka_name a
    INNER JOIN
        cast_info ci ON a.person_id = ci.person_id
),
company_details AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
movie_cast AS (
    SELECT
        rm.movie_id,
        COUNT(DISTINCT a.actor_id) AS total_actors,
        COUNT(DISTINCT cd.company_name) AS total_companies,
        MIN(CASE WHEN a.actor_order = 1 THEN a.actor_name END) AS first_actor
    FROM
        ranked_movies rm
    LEFT JOIN
        actor_info a ON rm.movie_id = a.movie_id
    LEFT JOIN
        company_details cd ON rm.movie_id = cd.movie_id
    GROUP BY
        rm.movie_id
)

SELECT 
    mc.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.total_actors, 0) AS total_actors,
    COALESCE(mc.total_companies, 0) AS total_companies,
    CASE
        WHEN mc.first_actor IS NULL THEN 'Unknown Lead Actor'
        ELSE mc.first_actor
    END AS lead_actor
FROM
    ranked_movies rm
LEFT JOIN
    movie_cast mc ON rm.movie_id = mc.movie_id
WHERE
    rm.rn = 1
    AND (rm.production_year >= 2000 OR mc.total_actors > 3)
ORDER BY
    rm.production_year DESC,
    mc.total_actors DESC
LIMIT 10;
This query showcases several SQL constructs including common table expressions (CTEs), window functions, outer joins, complicated predicates, and NULL logic. It retrieves information about movies produced in or after the year 2000, filtering for those with a lead actor or a specific count of total actors, and orders the results accordingly while managing NULLs through `COALESCE`.
