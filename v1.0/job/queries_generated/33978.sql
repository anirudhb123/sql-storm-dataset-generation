WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_ranked AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(c.actor_name, 'Unknown') AS main_actor,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_ranked c ON mh.movie_id = c.movie_id AND c.role_rank = 1
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.main_actor,
    md.keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    movie_details md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.title, md.production_year, md.main_actor, md.keywords
ORDER BY 
    md.production_year DESC,
    md.title ASC
LIMIT 50;
