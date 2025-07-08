
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS integer) AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id,
        e.title,
        e.production_year,
        e.kind_id,
        h.movie_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        an.name AS actor_name,
        r.role AS actor_role,
        COALESCE(c.nr_order, 999) AS display_order
    FROM 
        cast_info c
    JOIN 
        aka_name an ON c.person_id = an.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT it.info || ': ' || mi.info, '; ') WITHIN GROUP (ORDER BY it.info) AS info_summary
    FROM 
        movie_info mi
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.title AS "Movie Title",
    mh.production_year AS "Production Year",
    cd.actor_name AS "Actor Name",
    cd.actor_role AS "Role",
    COALESCE(mk.keywords, '') AS "Keywords",
    COALESCE(mis.info_summary, '') AS "Info Summary"
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%') OR mh.kind_id IS NULL)
ORDER BY 
    mh.production_year DESC,
    cd.display_order,
    mh.title;
