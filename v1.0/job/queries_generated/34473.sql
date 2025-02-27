WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title t ON t.episode_of_id = mh.movie_id
)
SELECT 
    a.name,
    a.person_id,
    m.title AS movie_title,
    m.production_year,
    m.level,
    windowed_roles.role_count,
    movie_info.info AS movie_description
FROM 
    aka_name a
INNER JOIN 
    cast_info ci ON a.person_id = ci.person_id
INNER JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN (
    SELECT 
        person_id,
        COUNT(*) AS role_count
    FROM 
        cast_info
    GROUP BY 
        person_id
) AS windowed_roles ON a.person_id = windowed_roles.person_id
LEFT JOIN 
    movie_info ON m.movie_id = movie_info.movie_id AND movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'description' LIMIT 1)
WHERE 
    m.level <= 2
    AND (m.production_year IS NULL OR m.production_year >= 2000)
ORDER BY 
    m.production_year DESC, m.level, a.name;
