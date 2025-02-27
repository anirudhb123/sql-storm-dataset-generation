WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to find all linked movies and their respective links
    SELECT 
        mk.movie_id, 
        ml.linked_movie_id, 
        1 AS depth
    FROM 
        movie_link ml
    JOIN 
        movie_keyword mk ON mk.movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')  -- assuming we are interested in sequels
    
    UNION ALL
    
    SELECT 
        mh.movie_id, 
        ml.linked_movie_id, 
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Prequel')
),

actor_movies AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
),

movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        mk.keyword AS movie_keyword,
        m.note AS movie_note,
        a.actor_name,
        ah.depth
    FROM 
        title t
    LEFT JOIN 
        movie_info m ON m.movie_id = t.id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Wikipedia')  -- Focusing on Wikipedia info
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        actor_movies a ON a.movie_id = t.id
    LEFT JOIN 
        movie_hierarchy ah ON ah.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
        AND (t.production_year > 2000 OR mk.keyword IS NOT NULL)
)

SELECT 
    md.title,
    md.production_year,
    COUNT(DISTINCT md.actor_name) AS actor_count,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
    MAX(md.depth) AS max_depth,
    CASE 
        WHEN COUNT(DISTINCT md.actor_name) = 0 THEN 'No actors'
        ELSE 'Has actors'
    END AS actor_presence,
    CASE 
        WHEN md.movie_note IS NULL THEN 'No additional notes'
        ELSE md.movie_note
    END AS note_status
FROM 
    movie_details md
GROUP BY 
    md.title, md.production_year
HAVING 
    COUNT(DISTINCT md.actor_name) > 0 
ORDER BY 
    md.production_year DESC, 
    actor_count DESC, 
    md.title;

