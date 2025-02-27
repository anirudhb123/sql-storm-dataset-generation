
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        m.linked_movie_id,
        1 AS depth
    FROM 
        movie_link m
    JOIN 
        title t ON t.id = m.movie_id
    WHERE 
        m.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link m ON m.movie_id = mh.linked_movie_id
    JOIN 
        title t ON t.id = m.linked_movie_id
    WHERE 
        m.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),

cast_ranks AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
),

keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    ARRAY_AGG(DISTINCT cr.actor_name) AS actor_names,
    kc.keyword_total,
    mh.depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_ranks cr ON cr.movie_id = mh.movie_id
LEFT JOIN 
    keyword_count kc ON kc.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth, kc.keyword_total
HAVING 
    kc.keyword_total >= 3 AND mh.depth <= 3
ORDER BY 
    mh.production_year DESC, movie_title;
