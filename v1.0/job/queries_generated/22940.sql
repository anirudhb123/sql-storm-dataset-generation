WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CTE_CastInfo AS (
    SELECT
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    INNER JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
CTE_MovieInfo AS (
    SELECT
        mi.movie_id,
        MAX(mi.info) AS most_recent_info
    FROM
        movie_info mi
    WHERE
        mi.info IS NOT NULL
    GROUP BY
        mi.movie_id
),
CTE_KeywordCount AS (
    SELECT
        mk.movie_id,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(ci.total_cast, 0) AS total_cast,
    COALESCE(ci.actor_names, 'No actors') AS actor_names,
    COALESCE(mo.most_recent_info, 'No info') AS recent_info,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM
    MovieHierarchy mh
LEFT JOIN
    CTE_CastInfo ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    CTE_MovieInfo mo ON mh.movie_id = mo.movie_id
LEFT JOIN
    CTE_KeywordCount kc ON mh.movie_id = kc.movie_id
WHERE
    (mh.production_year > 2000 AND m.kind_id IN (1, 2)) 
    OR (mh.production_year <= 2000 AND ci.total_cast IS NULL)
ORDER BY
    mh.production_year DESC,
    total_cast DESC,
    mh.title ASC
OFFSET (SELECT COUNT(*) FROM aka_title) / 2 ROWS
FETCH NEXT 10 ROWS ONLY;
