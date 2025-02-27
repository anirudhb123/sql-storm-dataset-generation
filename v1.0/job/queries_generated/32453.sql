WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE
        ml.linked_movie_id IS NOT NULL
),
ActorCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
KeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            WHEN m.production_year >= 2000 THEN 'Modern'
            WHEN m.production_year < 2000 AND m.production_year >= 1980 THEN '80s to 90s'
            ELSE 'Classic'
        END AS era
    FROM
        aka_title m
    LEFT JOIN
        ActorCounts ac ON m.id = ac.movie_id
    LEFT JOIN
        KeywordCounts kc ON m.id = kc.movie_id
),
FinalResult AS (
    SELECT
        md.*,
        mh.level AS hierarchy_level
    FROM
        MovieDetails md
    LEFT JOIN
        MovieHierarchy mh ON md.movie_id = mh.movie_id
)
SELECT
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.keyword_count,
    fr.era,
    fr.hierarchy_level
FROM
    FinalResult fr
WHERE
    fr.actor_count > 5
ORDER BY
    fr.production_year DESC, fr.actor_count DESC;
