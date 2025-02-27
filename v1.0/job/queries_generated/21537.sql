WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mh.movie_id, 
        CONCAT(mh.title, ' (Sequel)') AS title, 
        mh.production_year + 1, 
        level + 1
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
        AND mh.level < 3  -- Only consider sequels up to level 3
),
actor_roles AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, a.name
),
movie_info_with_status AS (
    SELECT 
        mk.movie_id,
        bo.movie_id IS NOT NULL AS has_box_office, 
        mi.note AS movie_note
    FROM 
        movie_keyword mk
    LEFT JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
    LEFT JOIN 
        complete_cast bo ON mk.movie_id = bo.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    a.actor_name,
    a.roles,
    COALESCE(TOTAL(ci.nr_order), 0) AS total_cast_order,
    COUNT(DISTINCT kw.keyword) AS unique_keywords,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    muh.has_box_office,
    mh.level
FROM 
    movie_hierarchy mh
JOIN 
    movie_info_with_status muh ON mh.movie_id = muh.movie_id
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    actor_roles a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword kw ON mh.movie_id = kw.movie_id 
WHERE 
    EXISTS (
        SELECT 1 
        FROM aka_title at 
        WHERE at.title ILIKE '%' || a.actor_name || '%' 
        AND at.production_year > (EXTRACT(YEAR FROM NOW()) - 5)
    )
GROUP BY 
    m.title, m.production_year, a.actor_name, a.roles, muh.has_box_office, mh.level
ORDER BY 
    total_cast_order DESC, 
    mh.production_year DESC
LIMIT 100;
