WITH ranked_movies AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS year_rank
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
    AND
        at.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'feature%'
        )
),
actor_stats AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(COALESCE(m.production_year, 0)) AS avg_movie_year
    FROM
        cast_info ci
    LEFT JOIN
        aka_title m ON ci.movie_id = m.id
    GROUP BY
        ci.person_id
),
top_actors AS (
    SELECT
        a.id,
        a.name,
        stats.total_movies,
        stats.avg_movie_year,
        RANK() OVER (ORDER BY stats.total_movies DESC) AS actor_rank
    FROM
        aka_name a
    JOIN
        actor_stats stats ON a.person_id = stats.person_id
    WHERE
        a.name IS NOT NULL
)
SELECT
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    ta.total_movies,
    ta.avg_movie_year,
    COALESCE(ta.avg_movie_year - rm.production_year, NULL) AS year_difference
FROM
    ranked_movies rm
LEFT JOIN
    top_actors ta ON rm.year_rank <= 5
WHERE
    rm.year_rank IS NOT NULL
ORDER BY
    rm.production_year DESC,
    ta.total_movies DESC
LIMIT 50;
