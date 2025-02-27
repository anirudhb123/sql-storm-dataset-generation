WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_with_role AS (
    SELECT 
       c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(DISTINCT cw.actor_name || ' (' || cw.role || ')', ', ') AS actors,
        COUNT(DISTINCT co.movie_id) AS co_movies_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_role cw ON mh.movie_id = cw.movie_id
    LEFT JOIN 
        movie_link co ON mh.movie_id = co.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No cast') AS actors,
    md.co_movies_count,
    CASE 
        WHEN md.co_movies_count > 0 THEN 'Linked'
        ELSE 'Standalone'
    END AS movie_type
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.title ASC;
