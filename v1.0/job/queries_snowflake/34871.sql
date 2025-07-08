
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    WHERE 
        mh.level < 3 
),
movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ci.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
aggregated_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        LISTAGG(m.actor_name, ', ') WITHIN GROUP (ORDER BY m.actor_name) AS actors,
        COUNT(m.actor_name) AS actor_count
    FROM 
        movies_with_cast m
    GROUP BY 
        m.movie_id, m.title, m.production_year
)

SELECT 
    am.movie_id,
    am.title,
    am.production_year,
    am.actor_count,
    COALESCE(am.actors, 'No actors available') AS actor_list
FROM 
    aggregated_movies am
LEFT JOIN 
    movie_info mi ON am.movie_id = mi.movie_id 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
WHERE 
    am.actor_count > 2
    AND (mi.info IS NULL OR CAST(mi.info AS FLOAT) > 1000000)
ORDER BY 
    am.production_year DESC, 
    am.title;
