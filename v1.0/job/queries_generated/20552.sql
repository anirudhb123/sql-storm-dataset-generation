-- This SQL query benchmarks performance using several advanced SQL constructs including CTEs, outer joins, window functions, and string manipulation.

WITH Recursive_Aggregated_Keywords AS (
    SELECT movie_id, k.keyword,
           ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY k.keyword) AS rn,
           COUNT(*) OVER (PARTITION BY movie_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
Ranked_Cast AS (
    SELECT ci.movie_id,
           a.name AS actor_name,
           ci.nr_order,
           RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),
Movies_With_Info AS (
    SELECT m.id AS movie_id,
           m.title,
           array_agg(DISTINCT ki.keyword) AS keywords,
           coalesce(mi.info, 'No info') AS movie_details
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info='summary' LIMIT 1)
    GROUP BY m.id, m.title, mi.info
)
SELECT mw.movie_id,
       mw.title,
       mw.keywords,
       rc.actor_name,
       rc.nr_order,
       CASE WHEN rc.actor_rank IS NULL THEN 'Unknown Rank'
            ELSE CAST(rc.actor_rank AS text) END AS actor_rank,
       ROW_NUMBER() OVER (PARTITION BY mw.movie_id ORDER BY rc.nr_order) AS performance_metric,
       nk.keyword_count AS total_keywords,
       LAG(mw.title) OVER (ORDER BY mw.movie_id) AS previous_movie,
       COUNT(*) OVER () AS total_movies
FROM Movies_With_Info mw
LEFT JOIN Ranked_Cast rc ON mw.movie_id = rc.movie_id
LEFT JOIN Recursive_Aggregated_Keywords nk ON mw.movie_id = nk.movie_id
WHERE mw.title IS NOT NULL
  AND (rc.nr_order < 2 OR rc.actor_name IS NOT NULL)
ORDER BY mw.movie_id, actor_rank DESC NULLS LAST;

-- Note: This query assumes a lot about the intended schema design and relationships, including outer joins and potential NULL scenarios.
