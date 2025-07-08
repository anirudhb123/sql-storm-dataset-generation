
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL AS episode_detail,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        'Episode ' || mt.season_nr || ' - ' || mt.episode_nr AS episode_detail,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id  
),
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS num_actors,
        MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles,
        LISTAGG(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No notes' END, '; ') WITHIN GROUP (ORDER BY ci.note) AS actor_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_kinds
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.episode_detail,
        cs.num_actors,
        cs.has_roles,
        cm.company_names,
        cm.company_kinds,
        COALESCE(mi.info, 'No info available') AS movie_info
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_statistics cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        company_movie_info cm ON mh.movie_id = cm.movie_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1
        )  
)
SELECT 
    md.movie_id,
    md.title,
    md.episode_detail,
    md.num_actors,
    md.has_roles,
    md.company_names,
    md.company_kinds,
    md.movie_info
FROM 
    movie_details md
WHERE 
    md.num_actors IS NOT NULL 
    AND (md.has_roles = 1 OR md.title LIKE '%Mystery%') 
ORDER BY 
    md.num_actors DESC,
    md.title ASC
LIMIT 50;
