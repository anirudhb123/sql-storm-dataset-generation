WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m2.title, 'N/A') AS linked_title,
        COALESCE(ca.name, 'Unknown Actor') AS actor_name,
        CASE 
            WHEN m.production_year IS NULL THEN 'Year Unknown' 
            ELSE CAST(m.production_year AS VARCHAR)
        END AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ca.nr_order) AS actor_order
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND 
        m.production_year IS NOT NULL
            OR EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info ILIKE '%Award%')
),
actor_counts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        MAX(production_year) AS last_movie_year
    FROM 
        movie_hierarchy
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_id) > 2
),
result AS (
    SELECT 
        mh.*,
        ac.movie_count,
        ac.last_movie_year
    FROM 
        movie_hierarchy mh
    JOIN 
        actor_counts ac ON mh.actor_name = ac.actor_name
)
SELECT 
    r.*,
    COALESCE(NULLIF(r.actor_name, ''), 'Anonymous') AS displayed_actor_name,
    CASE 
        WHEN r.last_movie_year < 2000 THEN 'Classics'
        WHEN r.last_movie_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
        ELSE 'Recent Hits'
    END AS era_category
FROM 
    result r
WHERE 
    r.movie_count > 5
ORDER BY 
    r.production_year DESC, 
    r.actor_order ASC;

