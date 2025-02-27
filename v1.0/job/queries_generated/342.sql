WITH MovieRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_role_id) AS role_count,
        AVG(m.production_year) AS avg_production_year
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title m ON c.movie_id = m.movie_id
    GROUP BY
        c.movie_id, a.name
),
TitleYears AS (
    SELECT
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS title_rank
    FROM
        title
)
SELECT
    T.title,
    T.production_year,
    COALESCE(MR.actor_name, 'Unknown') AS actor_name,
    MR.role_count,
    T.title_rank
FROM
    TitleYears T
LEFT JOIN
    MovieRoles MR ON T.title_id = MR.movie_id
WHERE
    T.production_year >= 2000
    AND (MR.role_count IS NOT NULL OR T.title_rank <= 5)
ORDER BY
    T.production_year DESC, T.title;
