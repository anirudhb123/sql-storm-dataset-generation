WITH RecursiveTitle AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        b.name AS person_name,
        c.role AS actor_role
    FROM
        aka_title a
    JOIN
        cast_info b ON a.id = b.movie_id
    JOIN
        role_type c ON b.person_role_id = c.id
    WHERE
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

ProcessedData AS (
    SELECT
        rt.movie_title,
        rt.production_year,
        rt.person_name,
        rt.actor_role,
        LENGTH(rt.movie_title) AS title_length,
        LEFT(rt.movie_title, 3) AS title_preview
    FROM
        RecursiveTitle rt
)

SELECT
    pd.movie_title,
    pd.production_year,
    pd.person_name,
    pd.actor_role,
    pd.title_length,
    pd.title_preview
FROM
    ProcessedData pd
WHERE
    pd.title_length > 10
ORDER BY
    pd.production_year DESC, pd.title_length DESC
LIMIT 50;
