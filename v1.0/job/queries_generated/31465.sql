WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE
        m.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
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
    r.actor_name,
    r.role_rank,
    r.total_roles,
    ks.keywords,
    COALESCE(mi.info, 'No Information') AS movie_info,
    NULLIF(mi.note, '') AS additional_note
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast r ON mh.movie_id = r.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level = 0 
ORDER BY 
    mh.production_year DESC, r.role_rank
LIMIT 100;
