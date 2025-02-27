WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        1 AS generation
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name LIKE '%Smith%'
    
    UNION ALL
    
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        ah.generation + 1 AS generation
    FROM cast_info c
    JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE c.nr_order > ah.nr_order
)

SELECT 
    t.title,
    t.production_year,
    a.person_id,
    a.generation,
    COUNT(DISTINCT a.person_id) OVER (PARTITION BY t.id) AS unique_actor_count,
    COUNT(*) OVER (PARTITION BY t.id) AS total_actors,
    COALESCE(mi.info, 'No Info') AS movie_info,
    string_agg(DISTINCT a.name, ', ') AS actor_names
FROM 
    title t
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    t.production_year >= 2000
    AND (c.note IS NULL OR c.note != 'Cameo')
    AND EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = t.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')
    )
GROUP BY 
    t.id, a.person_id, a.generation, mi.info
ORDER BY 
    t.production_year DESC, unique_actor_count DESC;

WITH movie_cast AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.nr_order = 1 THEN 1 ELSE 0 END) AS leading_roles
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
)

SELECT 
    mc.title,
    mc.production_year,
    mc.actor_count,
    mci.movie_info,
    CASE 
        WHEN mc.actor_count > 10 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_type
FROM 
    movie_cast mc
LEFT JOIN 
    (SELECT movie_id, STRING_AGG(info, '; ') AS movie_info 
     FROM movie_info 
     GROUP BY movie_id) mci ON mc.id = mci.movie_id
WHERE 
    mc.actor_count > 5
ORDER BY 
    mc.production_year DESC;
