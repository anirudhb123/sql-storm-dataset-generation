WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(p.name, 'Unknown') AS director,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_name p ON ml.linked_movie_id = p.person_id AND ml.link_type_id = (SELECT id FROM link_type WHERE link = 'director')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        COALESCE(np.name, 'Unknown') AS director,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        aka_name np ON ml.linked_movie_id = np.person_id AND ml.link_type_id = (SELECT id FROM link_type WHERE link = 'director')
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') as actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.director,
        COALESCE(cd.actor_count, 0) AS actor_count,
        COALESCE(cd.actors, 'None') AS actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
)
SELECT 
    mwc.title,
    mwc.director,
    mwc.actor_count,
    mwc.actors,
    COALESCE(CAST(AVG(mi.production_year) FILTER (WHERE mi.production_year IS NOT NULL) OVER (PARTITION BY mwc.director) AS INT), 0) AS avg_production_year
FROM 
    movie_with_cast mwc
LEFT JOIN 
    aka_title mi ON mwc.movie_id = mi.id
WHERE 
    mwc.actor_count > 0
    AND (mwc.director IS NOT NULL OR mwc.director = 'Unknown')
ORDER BY 
    mwc.actor_count DESC, 
    avg_production_year ASC
LIMIT 25;
