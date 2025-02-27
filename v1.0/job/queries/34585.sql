WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.production_year, 0) AS production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        COALESCE(at.production_year, 0),
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        pt.role AS person_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type pt ON c.role_id = pt.id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.person_role,
    cd.actor_rank,
    ks.keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mh.movie_id) AS company_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id AND mi.note IS NOT NULL) AS info_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.production_year > 2000
ORDER BY 
    mh.production_year DESC, mh.title, cd.actor_rank
LIMIT 100;