WITH recursive movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mh.depth < 5
),
distinct_cast AS (
    SELECT DISTINCT
        c.movie_id,
        c.person_id,
        a.name AS actor_name
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1
),
fin_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(dc.actor_name, 'Unknown Actor') AS main_actor,
        COUNT(DISTINCT mc.company_id) AS num_production_companies,
        SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS row_num
    FROM movie_hierarchy mh
    LEFT JOIN distinct_cast dc ON mh.movie_id = dc.movie_id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, dc.actor_name
)
SELECT 
    f.title,
    f.production_year,
    f.main_actor,
    f.num_production_companies,
    f.total_budget,
    CASE 
        WHEN f.num_production_companies = 0 THEN 'No Companies'
        WHEN f.total_budget IS NULL THEN 'Budget Unavailable'
        ELSE 'Available'
    END AS budget_status
FROM fin_info f
WHERE f.row_num = 1
AND f.production_year BETWEEN 2000 AND 2023
ORDER BY f.total_budget DESC NULLS LAST
LIMIT 10;
