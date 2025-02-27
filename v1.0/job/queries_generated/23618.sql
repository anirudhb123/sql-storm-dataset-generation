WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        depth + 1
    FROM aka_title mt
    JOIN movie_link ml ON ml.movie_id = movie_hierarchy.movie_id
    WHERE ml.linked_movie_id = mt.id
),
actor_cast AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COALESCE(c.note, 'No Note') AS cast_note,
        COALESCE(c.nr_order, -1) AS nr_order
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
),
info_aggregate AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
keyword_aggregate AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
comp_count AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
final_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ac.actor_id) AS total_actors,
        MAX(cc.company_count) AS total_companies,
        ia.movie_info,
        ka.keywords,
        MAX(ac.actor_order) AS highest_actor_order
    FROM movie_hierarchy mh
    LEFT JOIN actor_cast ac ON mh.movie_id = ac.movie_id
    LEFT JOIN comp_count cc ON mh.movie_id = cc.movie_id
    LEFT JOIN info_aggregate ia ON mh.movie_id = ia.movie_id
    LEFT JOIN keyword_aggregate ka ON mh.movie_id = ka.movie_id
    WHERE mh.production_year BETWEEN 1990 AND 2023
    GROUP BY mh.movie_id, mh.title, mh.production_year
)
SELECT 
    *,
    CASE 
        WHEN highest_actor_order > 5 THEN 'Star'
        WHEN total_companies IS NULL OR total_companies = 0 THEN 'Independent'
        ELSE 'Standard'
    END AS movie_classification,
    NULLIF(regexp_replace(movie_info, '[^\w\s]', '', 'g'), '') AS cleaned_movie_info
FROM final_result
ORDER BY total_actors DESC, production_year ASC, title ASC
LIMIT 100;
