WITH RECURSIVE movie_hierarchy AS (
    -- Initial anchor member for recursive CTE to fetch movie and its direct linked movies
    SELECT
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    
    UNION ALL
    
    -- Recursive member to fetch linked movies
    SELECT
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id 
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
),

-- Aggregate the popular movie based on keywords and cast
keyword_movie AS (
    SELECT 
        m.id AS movie_id,
        string_agg(k.keyword, ', ') AS keywords,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m 
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

-- Fetching the cast member names with roles for specific movies and their related movies
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rt.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
),

-- Final selection to evaluate performance and depth of cast and keyword associations
final_selection AS (
    SELECT 
        mh.root_movie_id,
        t.title,
        COALESCE(km.keywords, 'None') AS keywords,
        km.keyword_count,
        string_agg(cd.actor_name || ' as ' || cd.actor_role, ', ') AS cast_details,
        depth AS orginal_depth
    FROM 
        movie_hierarchy mh
    JOIN 
        title t ON mh.linked_movie_id = t.id
    LEFT JOIN 
        keyword_movie km ON t.id = km.movie_id
    LEFT JOIN 
        cast_details cd ON t.id = cd.movie_id
    GROUP BY 
        mh.root_movie_id, t.title, km.keywords, km.keyword_count
)

SELECT 
    f.root_movie_id,
    f.title,
    f.keywords,
    f.keyword_count,
    f.cast_details,
    COUNT(f.cast_details) OVER (PARTITION BY f.root_movie_id) AS total_cast_count
FROM 
    final_selection f
ORDER BY 
    f.keyword_count DESC, f.cast_details ASC;
