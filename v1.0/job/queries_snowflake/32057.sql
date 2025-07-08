
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        movie_id,
        title,
        season_nr,
        episode_nr,
        1 AS depth
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL 

    UNION ALL

    SELECT 
        at.movie_id,
        at.title,
        at.season_nr,
        at.episode_nr,
        mh.depth + 1
    FROM 
        aka_title at
    JOIN 
        movie_hierarchy mh ON at.episode_of_id = mh.movie_id 
),

movie_cast AS (
    SELECT 
        m.movie_id,
        m.title,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        movie_hierarchy m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movie_information AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT it.info, '; ') WITHIN GROUP (ORDER BY it.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.season_nr,
    mh.episode_nr,
    COALESCE(mc.actor_name, 'Unknown actor') AS lead_actor,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.info_details, 'No information') AS movie_info,
    CASE 
        WHEN mh.depth > 1 THEN 'Episode'
        ELSE 'Movie'
    END AS type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id AND mc.actor_rank = 1 
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id 
LEFT JOIN 
    movie_information mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.season_nr IS NULL OR mh.episode_nr IS NOT NULL 
GROUP BY 
    mh.movie_id, mh.title, mh.season_nr, mh.episode_nr, mh.depth, mc.actor_name, mk.keywords, mi.info_details
ORDER BY 
    mh.movie_id;
