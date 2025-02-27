
WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.season_nr, mt.episode_nr, 1 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL 

    UNION ALL

    SELECT mt.id, mt.title, mt.season_nr, mt.episode_nr, mh.level + 1
    FROM aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
actor_movie_roles AS (
    SELECT
        a.name AS actor_name,
        mt.title AS movie_title,
        COUNT(DISTINCT ci.role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT ci.role_id) DESC) AS actor_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
    GROUP BY a.name, mt.title
),
movie_details AS (
    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        NULLIF(COUNT(DISTINCT mw.keyword_id), 0) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mw ON mt.id = mw.movie_id
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
final_output AS (
    SELECT
        mh.title AS episode_title,
        mh.season_nr,
        mh.episode_nr,
        md.production_year,
        md.actors,
        COALESCE(md.keyword_count, 0) AS keyword_count,
        ar.role_count AS unique_roles
    FROM movie_hierarchy mh
    LEFT JOIN movie_details md ON mh.title = md.title
    LEFT JOIN actor_movie_roles ar ON ar.movie_title = mh.title
)
SELECT *
FROM final_output
WHERE keyword_count > 3
AND unique_roles > 2
ORDER BY production_year DESC, season_nr, episode_nr;
