WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        mh.level + 1
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
actor_movies AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
full_movie_info AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        am.actor_name,
        mk.keywords,
        COUNT(DISTINCT ci.id) AS total_cast
    FROM movie_hierarchy mh
    LEFT JOIN actor_movies am ON mh.movie_id = am.movie_id
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, am.actor_name, mk.keywords
)
SELECT 
    fmi.movie_id,
    fmi.title,
    fmi.production_year,
    MAX(fmi.actor_order) AS total_actors,
    CASE 
        WHEN fmi.keywords IS NULL THEN 'No Keywords'
        ELSE fmi.keywords
    END AS keywords_list,
    COALESCE(SUM(CASE WHEN fmi.actor_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS valid_actor_count
FROM full_movie_info fmi
GROUP BY fmi.movie_id, fmi.title, fmi.production_year
HAVING COUNT(fmi.actor_name) > 2
ORDER BY fmi.production_year DESC, fmi.title;
