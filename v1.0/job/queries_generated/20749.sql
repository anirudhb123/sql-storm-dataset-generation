WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), movie_cast AS (
    SELECT 
        ct.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count, 
        MAX(CASE WHEN ci.nr_order = 1 THEN ak.name END) AS lead_actor_name
    FROM 
        complete_cast ct
    LEFT JOIN 
        cast_info ci ON ct.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ct.movie_id
), movie_info_aggregated AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(DISTINCT mi.info ORDER BY mi.info) AS info_summary
    FROM 
        movie_info mi
    JOIN 
        movie_hierarchy m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mc.actor_count, 0) AS total_actors,
    mc.lead_actor_name,
    COALESCE(mia.info_summary, 'No additional info') AS aggregated_info,
    CASE 
        WHEN mh.level = 0 THEN 'Original Movie'
        ELSE 'Sequel or Related Movie'
    END AS movie_type,
    (SELECT COUNT(*) 
        FROM movie_keyword mk 
        WHERE mk.movie_id = mh.movie_id 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')) AS action_keyword_count,
    COUNT(DISTINCT mi.id) AS distinct_info_entries
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_aggregated mia ON mh.movie_id = mia.movie_id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
GROUP BY 
    mh.movie_id, mc.actor_count, mc.lead_actor_name, mia.info_summary, mh.level
HAVING 
    COALESCE(mc.actor_count, 0) > 1
ORDER BY 
    mh.production_year DESC, action_keyword_count DESC;
