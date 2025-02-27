WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        CAST(0 AS INTEGER) AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
),
cast_details AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cd.actor_name,
    cd.actor_order,
    mk.keywords,
    COALESCE(cd.actor_name, 'Unknown') AS actor_name,
    COUNT(DISTINCT cd.cast_id) OVER (PARTITION BY mh.movie_id) AS total_actors,
    STRING_AGG(DISTINCT cd.actor_name, ', ') AS all_actors,
    cd.actor_order AS actor_order,
    cdt.company_name,
    cdt.company_type
FROM movie_hierarchy mh
LEFT JOIN cast_details cd ON cd.movie_title = mh.movie_title
LEFT JOIN movie_keywords mk ON mk.movie_id = mh.movie_id
LEFT JOIN company_details cdt ON cdt.movie_id = mh.movie_id
WHERE mh.production_year >= 2000 
AND (cd.actor_order IS NULL OR cd.actor_order <= 5)
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, 
    cd.actor_name, cd.actor_order, cdt.company_name, cdt.company_type
ORDER BY 
    mh.production_year DESC, total_actors DESC, mh.movie_title;
