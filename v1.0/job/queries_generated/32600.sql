WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
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
cast_role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        ci.movie_id, rt.role
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        SUM(CASE WHEN cr.actor_count > 0 THEN cr.actor_count ELSE 1 END) AS total_actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_role_summary cr ON cr.movie_id = mh.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    ORDER BY 
        total_actors DESC
    LIMIT 10
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(ti.info, 'No additional info') AS additional_info,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.movie_id) AS info_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = tm.movie_id) AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_info ti ON ti.movie_id = tm.movie_id AND ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
ORDER BY 
    tm.production_year DESC;
