WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(COUNT(DISTINCT cast.person_id), 0) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) FILTER (WHERE a.name IS NOT NULL) AS actor_names
    FROM
        aka_title t
    LEFT JOIN
        cast_info cast ON t.movie_id = cast.movie_id
    LEFT JOIN
        aka_name a ON cast.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),

CompleteMovieInfo AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        MovieDetails md
    LEFT JOIN
        MovieKeywords mk ON md.movie_id = mk.movie_id
)

SELECT
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.actor_count,
    cm.actor_names,
    cm.keywords,
    CASE
        WHEN cm.production_year < 1980 THEN 'Classic'
        WHEN cm.production_year BETWEEN 1980 AND 2000 THEN 'Modern Classic'
        ELSE 'Contemporary'
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY cm.production_year ORDER BY cm.actor_count DESC) AS popularity_rank
FROM
    CompleteMovieInfo cm
WHERE
    cm.actor_count > 0
UNION ALL
SELECT
    -1 AS movie_id,
    'No Movies' AS title,
    NULL AS production_year,
    0 AS actor_count,
    ARRAY[]::text[] AS actor_names,
    'No keywords' AS keywords,
    'N/A' AS era,
    NULL AS popularity_rank
WHERE NOT EXISTS (SELECT 1 FROM CompleteMovieInfo)
ORDER BY
    cm.production_year DESC NULLS LAST;
