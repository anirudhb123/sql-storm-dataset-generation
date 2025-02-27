WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS title_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(episodes.season_nr, 0) AS season,
        COALESCE(episodes.episode_nr, 0) AS episode,
        0 AS depth
    FROM title mt
    LEFT JOIN title episodes ON mt.id = episodes.episode_of_id
    UNION ALL
    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(episodes.season_nr, 0),
        COALESCE(episodes.episode_nr, 0),
        depth + 1
    FROM title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.title_id
),
cast_info_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT akn.name, ', ') AS actor_names
    FROM cast_info ci
    INNER JOIN aka_name akn ON ci.person_id = akn.person_id
    GROUP BY ci.movie_id
),
keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_info_summary AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Director' THEN mi.info END) AS director,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT
    mh.title_id,
    mh.title,
    mh.production_year,
    COALESCE(mis.director, 'Unknown') AS director,
    COALESCE(mis.genre, 'Unknown') AS genre,
    COALESCE(cis.total_cast_members, 0) AS total_cast,
    COALESCE(cis.actor_names, 'No Actors') AS actors,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(mis.season, 0) AS season,
    COALESCE(mis.episode, 0) AS episode,
    mh.depth
FROM movie_hierarchy mh
LEFT JOIN movie_info_summary mis ON mh.title_id = mis.movie_id
LEFT JOIN cast_info_summary cis ON mh.title_id = cis.movie_id
LEFT JOIN keyword_count kc ON mh.title_id = kc.movie_id
WHERE mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
  AND mh.production_year IS NOT NULL
  AND (mh.production_year >= 2000 OR mh.depth <= 1)
ORDER BY mh.production_year DESC, mh.title;
