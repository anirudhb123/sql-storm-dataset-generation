WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(t2.title, 'N/A') AS linked_title,
        t.link_type_id,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        title t2 ON ml.linked_movie_id = t2.id
    LEFT JOIN 
        link_type t ON ml.link_type_id = t.id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        COALESCE(t2.title, 'N/A') AS linked_title,
        t.link_type_id,
        level + 1
    FROM 
        movie_hierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title t2 ON ml.linked_movie_id = t2.id
    LEFT JOIN 
        link_type t ON ml.link_type_id = t.id
    WHERE 
        level < 3
),
complex_cast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS filled_roles
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.linked_title,
        mh.level,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(cc.actor_names, 'No actors') AS actor_names,
        COALESCE(cc.filled_roles, 0) AS filled_roles
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complex_cast cc ON mh.movie_id = cc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.linked_title,
    md.level,
    md.cast_count,
    md.actor_names,
    md.filled_roles,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    (SELECT COUNT(DISTINCT movie_id) FROM movie_link ml WHERE ml.linked_movie_id = md.movie_id) AS linked_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) AS has_budget_info,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
       FROM movie_keyword mk 
       JOIN keyword k ON mk.keyword_id = k.id 
       WHERE mk.movie_id = md.movie_id) AS keywords
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
    AND (md.linked_title IS NOT NULL OR linked_count > 0)
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 50;
