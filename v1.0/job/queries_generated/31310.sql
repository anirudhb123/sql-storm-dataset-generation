WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        h.level + 1
    FROM
        movie_hierarchy h
    JOIN
        aka_title m ON m.episode_of_id = h.movie_id
),
cast_ranking AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
),
movie_info_enriched AS (
    SELECT
        m.movie_id,
        m.title,
        COALESCE(mi.info, 'No Info Available') AS additional_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_hierarchy m
    LEFT JOIN
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY
        m.movie_id, m.title, mi.info
),
final_selection AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        cr.actor_name,
        cr.actor_rank,
        mi.additional_info,
        mi.keyword_count
    FROM
        movie_hierarchy mh
    LEFT JOIN
        cast_ranking cr ON mh.movie_id = cr.movie_id
    LEFT JOIN
        movie_info_enriched mi ON mh.movie_id = mi.movie_id
)
SELECT
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.kind_id,
    GROUP_CONCAT(DISTINCT fs.actor_name ORDER BY fs.actor_rank) AS actors,
    fs.additional_info,
    fs.keyword_count
FROM
    final_selection fs
WHERE
    fs.production_year >= 2000
    AND fs.keyword_count > 1
GROUP BY
    fs.movie_id, fs.title, fs.production_year, fs.kind_id
ORDER BY
    fs.production_year DESC, fs.title;
