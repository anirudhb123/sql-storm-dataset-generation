WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM
        aka_title mt
    JOIN
        movie_hierarchy mh ON mh.movie_id = mt.episode_of_id
),

cast_details AS (
    SELECT
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY
        ci.movie_id
),

movie_info_summary AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mh.level, 0) AS hierarchy_level,
        CASE
            WHEN m.kind_id IS NULL THEN 'Unknown'
            ELSE kt.kind
        END AS kind
    FROM
        aka_title m
    LEFT JOIN
        kind_type kt ON kt.id = m.kind_id
    LEFT JOIN
        movie_hierarchy mh ON mh.movie_id = m.id
),

final_summary AS (
    SELECT
        mis.movie_id,
        mis.title,
        mis.hierarchy_level,
        mis.kind,
        COALESCE(cd.total_cast, 0) AS total_cast,
        cd.actor_names
    FROM
        movie_info_summary mis
    LEFT JOIN
        cast_details cd ON cd.movie_id = mis.movie_id
)

SELECT
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.hierarchy_level,
    fs.kind,
    fs.total_cast,
    fs.actor_names
FROM
    final_summary fs
LEFT JOIN
    movie_keyword mk ON mk.movie_id = fs.movie_id
JOIN
    keyword kw ON kw.id = mk.keyword_id
WHERE
    fs.hierarchy_level < 5
    AND (fs.kind <> 'Unknown' OR fs.total_cast > 3)
ORDER BY
    fs.production_year DESC, fs.hierarchy_level, fs.title
LIMIT 50;
This SQL query combines recursive common table expressions (CTEs) to create a movie hierarchy structure, aggregates cast information using window functions and string aggregation, implements outer joins, and applies various predicates while working with diverse tables and relationships from the provided schema. It also includes NULL handling using the `COALESCE` function to ensure robust results.
