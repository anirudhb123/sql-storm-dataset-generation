WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        mh.level < 5  -- Limiting to 5 levels depth
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        cs.total_cast,
        cs.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.total_cast DESC) AS rank
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_summary cs ON mh.movie_id = cs.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    rm.keyword,
    COALESCE(rm.total_cast, 0) AS total_cast,
    rm.cast_names,
    CASE 
        WHEN rm.total_cast IS NULL THEN 'No Cast Available'
        WHEN rm.total_cast < 3 THEN 'Limited Cast'
        ELSE 'Robust Cast'
    END AS cast_quality
FROM
    ranked_movies rm
WHERE
    rm.rank <= 10  -- Limit to top 10 movies per year
ORDER BY
    rm.production_year DESC,
    rm.rank;
