
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ed.id AS movie_id,
        ed.title,
        ed.production_year,
        mh.level + 1,
        mh.title AS parent_movie_title
    FROM 
        aka_title ed
    JOIN 
        movie_hierarchy mh ON ed.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS noted_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

final_summary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cm.kind AS company_type,
        cs.actor_count,
        cs.noted_actors,
        ks.keywords,
        COALESCE(si.info, 'No Info Available') AS other_info
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON mh.movie_id = ks.movie_id
    LEFT JOIN 
        movie_info si ON mh.movie_id = si.movie_id 
        AND si.info_type_id IN (
            SELECT 
                id 
            FROM 
                info_type 
            WHERE 
                info ILIKE '%award%'
        )
)

SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.company_type,
    fs.actor_count,
    fs.noted_actors,
    fs.keywords,
    fs.other_info
FROM 
    final_summary fs
WHERE 
    fs.actor_count > 0 OR fs.noted_actors > 0
ORDER BY 
    fs.production_year DESC, 
    fs.actor_count DESC;
