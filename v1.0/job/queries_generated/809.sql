WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(mo.company_count, 0) AS company_count,
        COALESCE(k.keyword_count, 0) AS keyword_count
    FROM
        title t
    LEFT JOIN (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        GROUP BY
            mc.movie_id
    ) mo ON t.id = mo.movie_id
    LEFT JOIN (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM
            movie_keyword mk
        GROUP BY
            mk.movie_id
    ) k ON t.id = k.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.company_count,
    cd.actor_count,
    cd.actors,
    CASE
        WHEN md.company_count > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status
FROM
    MovieDetails md
LEFT JOIN
    CastDetails cd ON md.title_id = cd.movie_id
WHERE
    md.production_year > 2000
ORDER BY
    md.production_year DESC,
    md.title ASC;
