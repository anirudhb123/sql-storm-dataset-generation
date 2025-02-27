WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT
        ca.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS appearances
    FROM
        cast_info ca
    JOIN
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY
        ca.movie_id, ak.name
    HAVING
        COUNT(*) > 1
),
MovieDetails AS (
    SELECT
        mt.title_id,
        mt.title,
        mt.production_year,
        COALESCE(ka.actor_name, 'Unknown Actor') AS actor_name,
        mt.year_rank
    FROM
        RankedTitles mt
    LEFT JOIN
        TopActors ka ON mt.title_id = ka.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.actor_name,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    CASE
        WHEN md.year_rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS ranking_category
FROM
    MovieDetails md
LEFT JOIN
    movie_companies mc ON md.title_id = mc.movie_id AND mc.company_type_id = (
        SELECT id FROM company_type WHERE kind = 'Production' LIMIT 1
    )
WHERE
    md.actor_name IS NOT NULL OR md.production_year >= 2000
ORDER BY
    md.production_year DESC, md.title;
