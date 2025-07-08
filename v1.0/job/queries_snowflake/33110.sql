
WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.episode_of_id, 1 AS depth
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT mt.id, mt.title, mt.production_year, mt.episode_of_id, mh.depth + 1
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT ci.movie_id, 
           ak.name,
           RANK() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
company_roles AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT cc.kind) AS company_count,
           LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN comp_cast_type cc ON ct.kind = cc.kind
    GROUP BY mc.movie_id
),
movie_info_with_keywords AS (
    SELECT mi.movie_id,
           mi.info,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_info mi
    LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY mi.movie_id, mi.info
)
SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(rc.name, 'Unknown') AS main_actor,
       COALESCE(cr.companies, 'No companies listed') AS companies,
       kw.keyword_count,
       mh.depth,
       CASE 
           WHEN mh.depth > 1 THEN 'Sub-series'
           ELSE 'Standalone'
       END AS series_type
FROM movie_hierarchy mh
LEFT JOIN ranked_cast rc ON mh.movie_id = rc.movie_id AND rc.rank_order = 1
LEFT JOIN company_roles cr ON mh.movie_id = cr.movie_id
LEFT JOIN movie_info_with_keywords kw ON mh.movie_id = kw.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.production_year DESC, mh.title;
