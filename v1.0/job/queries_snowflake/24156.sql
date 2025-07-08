
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM title m
    WHERE m.episode_of_id IS NULL  
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        CONCAT(mh.path, ' -> ', e.title) AS path
    FROM title e
    JOIN movie_hierarchy mh ON mh.movie_id = e.episode_of_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_sequence
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM movie_keyword mt
    JOIN keyword kw ON mt.keyword_id = kw.id
    GROUP BY mt.movie_id
),
movies_with_info AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mii.info, '; ') WITHIN GROUP (ORDER BY mii.info) AS additional_info
    FROM movie_info mi
    JOIN movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY mi.movie_id
)
SELECT 
    mh.movie_id, 
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COALESCE(cd.actor_name, 'Unknown Actor') AS leading_actor,
    cd.actor_sequence,
    COALESCE(mwk.keywords, 'No Keywords') AS keywords,
    COALESCE(mwi.additional_info, 'No Additional Info') AS additional_info
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id AND cd.actor_sequence = 1
LEFT JOIN movies_with_keywords mwk ON mh.movie_id = mwk.movie_id
LEFT JOIN movies_with_info mwi ON mh.movie_id = mwi.movie_id
WHERE mh.production_year IS NOT NULL
AND mh.production_year > 1990
ORDER BY mh.production_year DESC, mh.level, mh.title;
