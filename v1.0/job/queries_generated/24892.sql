WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level,
        mt.production_year,
        NULL::text AS parent_title
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1 AS level,
        m.production_year,
        mh.movie_title AS parent_title
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_with_roles AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        cr.role AS role_name,
        RANK() OVER (PARTITION BY ca.movie_id ORDER BY ak.name) AS actor_rank
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    JOIN role_type cr ON ca.role_id = cr.id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

movie_info_with_notes AS (
    SELECT 
        mi.movie_id,
        mi.info AS movie_info,
        COALESCE(mi.note, 'No additional notes') AS note
    FROM movie_info mi
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.parent_title,
    cw.actor_name,
    cw.role_name,
    mw.keywords,
    mw.movie_info,
    mw.note,
    COUNT(cw.actor_name) OVER (PARTITION BY mh.movie_id) AS total_cast,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Unknown'
        WHEN mh.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_era,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = mh.movie_id 
     AND mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')) AS usa_company_count
FROM movie_hierarchy mh
LEFT JOIN cast_with_roles cw ON mh.movie_id = cw.movie_id
LEFT JOIN movie_keywords mw ON mh.movie_id = mw.movie_id
LEFT JOIN movie_info_with_notes mn ON mh.movie_id = mn.movie_id
ORDER BY mh.movie_title, cw.actor_rank
LIMIT 100;

