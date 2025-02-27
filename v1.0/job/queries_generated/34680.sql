WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM aka_title et
    INNER JOIN movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

cast_details AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(ak.name ORDER BY ci.nr_order) AS actor_names,
        COUNT(ci.id) AS total_actors
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),

title_info AS (
    SELECT 
        title.id,
        title.title,
        title.production_year,
        coalesce(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY k.keyword) AS keyword_rank
    FROM aka_title title 
    LEFT JOIN movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_names,
    cd.total_actors,
    ti.keyword
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN title_info ti ON mh.movie_id = ti.id
WHERE mh.production_year >= 2000
  AND mh.level < 3
  AND (ti.keyword IS NOT NULL OR cd.total_actors > 0)

ORDER BY mh.production_year DESC, mh.level ASC, ti.keyword_rank;
