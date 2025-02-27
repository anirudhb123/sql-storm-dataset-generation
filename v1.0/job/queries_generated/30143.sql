WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM title mt
    WHERE mt.id IS NOT NULL 

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
keyword_count AS (
    SELECT 
        mk.movie_id, 
        COUNT(k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    cd.actor_order,
    cd.actor_name || ' played the role of ' || cd.role || 
    ' in ' || mh.title || ' (' || mh.production_year || ') from companies: ' || 
    COALESCE(cod.companies, 'No companies listed') AS movie_info
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN keyword_count kc ON mh.movie_id = kc.movie_id
LEFT JOIN company_details cod ON mh.movie_id = cod.movie_id
WHERE mh.level = 1
ORDER BY mh.production_year DESC, cd.actor_order;
