WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000  

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE
        mh.level < 5  
),
movie_stats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        AVG(mk.keyword_count) AS avg_keywords
    FROM
        movie_hierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN (
        SELECT
            movie_id,
            COUNT(*) AS keyword_count
        FROM
            movie_keyword
        GROUP BY
            movie_id
    ) mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
),
ranked_movies AS (
    SELECT
        ms.*,
        RANK() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC) AS rank_within_year,
        ROW_NUMBER() OVER (ORDER BY ms.actor_count DESC) AS overall_rank
    FROM
        movie_stats ms
)
SELECT
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    rm.avg_keywords,
    rm.rank_within_year,
    rm.overall_rank
FROM
    ranked_movies rm
WHERE
    rm.rank_within_year <= 5  
ORDER BY
    rm.production_year DESC,
    rm.actor_count DESC;