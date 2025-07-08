
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
        h.depth + 1
    FROM 
        movie_link l
    JOIN 
        aka_title m ON l.linked_movie_id = m.id
    JOIN 
        movie_hierarchy h ON l.movie_id = h.movie_id
    WHERE 
        h.depth < 3  
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_stats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.actor_name) AS total_actors,
        LISTAGG(DISTINCT c.actor_name, ', ') WITHIN GROUP (ORDER BY c.actor_name) AS actor_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
keyword_aggregate AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    ms.title,
    ms.production_year,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    ms.total_actors,
    ms.actor_list
FROM 
    movie_stats ms
LEFT JOIN 
    keyword_aggregate ks ON ms.movie_id = ks.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.total_actors DESC;
