WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.imdb_index) AS rn,
        COALESCE(mo.info, 'No info available') AS movie_info
    FROM
        aka_title t
    LEFT JOIN
        movie_info mo ON mo.movie_id = t.id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime' LIMIT 1)
    WHERE
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT
        mk.movie_id,
        mk.keyword_id,
        COUNT(distinct c.person_id) AS actor_count
    FROM
        movie_keyword mk
    JOIN
        cast_info c ON c.movie_id = mk.movie_id
    GROUP BY
        mk.movie_id, mk.keyword_id
    HAVING
        COUNT(DISTINCT c.person_id) > 3
),
PersonRoles AS (
    SELECT
        ci.movie_id,
        r.role AS person_role,
        COUNT(ci.id) AS role_count,
        MIN(CASE WHEN ci.note IS NULL THEN 'No Note' ELSE ci.note END) AS notes
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id, r.role
    HAVING
        COUNT(ci.id) > 1
),
ComplexQuery AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(fr.actor_count, 0) AS actor_count,
        COALESCE(pr.role_count, 0) AS role_count,
        pr.notes
    FROM
        RankedMovies rm
    FULL OUTER JOIN
        FilteredCast fr ON rm.movie_id = fr.movie_id
    LEFT JOIN
        PersonRoles pr ON rm.movie_id = pr.movie_id
    WHERE
        rm.rn <= 5
        OR (pr.role_count IS NOT NULL AND pr.role_count > 2)
)
SELECT
    cq.movie_id,
    cq.title,
    cq.production_year,
    cq.actor_count,
    cq.role_count,
    cq.notes,
    CASE
        WHEN cq.actor_count > 5 THEN 'Star-studded'
        WHEN cq.role_count > 3 THEN 'Diverse Roles'
        ELSE 'Niche'
    END AS movie_type
FROM
    ComplexQuery cq
WHERE
    cq.production_year BETWEEN 2000 AND 2023
ORDER BY
    cq.production_year DESC, cq.actor_count DESC;
