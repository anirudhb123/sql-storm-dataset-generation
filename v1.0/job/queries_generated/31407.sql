WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL -- Start with top-level movies (not episodes)

    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id  -- Join to get episodes
),

movie_info_summary AS (
    SELECT 
        movie_id,
        STRING_AGG(info, '; ') AS info_list,
        COUNT(*) AS info_count
    FROM 
        movie_info
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info IN ('Synopsis', 'Rating'))
    GROUP BY 
        movie_id
),

cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        c.movie_id
),

movie_keywords AS (
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
    COALESCE(mis.info_list, 'No info available') AS movie_info,
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cd.actor_names, 'No actors listed') AS actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;
