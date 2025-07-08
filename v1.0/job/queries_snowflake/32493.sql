
WITH RECURSIVE movie_series AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS series_level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        ms.series_level + 1
    FROM
        aka_title e
    INNER JOIN movie_series ms ON e.episode_of_id = ms.movie_id
),
cast_with_roles AS (
    SELECT
        ci.movie_id,
        COUNT(*) AS num_actors,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
movie_info_with_keywords AS (
    SELECT
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
movie_info_ext AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No info available') AS info,
        COALESCE(mk.keywords, ARRAY_CONSTRUCT()) AS keywords,
        COALESCE(cr.num_actors, 0) AS actor_count,
        ms.series_level
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        movie_info_with_keywords mk ON m.id = mk.movie_id
    LEFT JOIN
        cast_with_roles cr ON m.id = cr.movie_id
    LEFT JOIN
        movie_series ms ON m.id = ms.movie_id
    WHERE
        m.production_year >= 2000 AND
        (m.kind_id = 1 OR m.kind_id IS NULL)
)
SELECT
    title,
    info,
    keywords,
    actor_count,
    series_level
FROM
    movie_info_ext
WHERE
    actor_count > 5
ORDER BY
    series_level DESC, actor_count DESC
LIMIT 100;
