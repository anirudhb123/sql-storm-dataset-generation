
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        mh.level + 1
    FROM aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'BoxOffice' THEN mi.info ELSE NULL END) AS box_office,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info ELSE NULL END) AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    mh.level,
    cs.total_cast,
    cs.cast_names,
    ks.keywords,
    mis.box_office,
    mis.genre
FROM movie_hierarchy mh
LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE (mh.production_year >= 2000 AND mh.production_year < 2024)
  AND (mh.kind_id = (SELECT kt.id FROM kind_type kt WHERE kt.kind = 'movie'))
ORDER BY mh.production_year DESC, mh.title
LIMIT 50;
