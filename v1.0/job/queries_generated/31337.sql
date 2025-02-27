WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS depth
    FROM cast_info ci
    WHERE ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
    
    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.depth + 1
    FROM cast_info ci
    JOIN actor_hierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id <> ah.person_id
    AND ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
),
movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_info_extended AS (
    SELECT mi.movie_id, MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
           MAX(CASE WHEN it.info = 'duration' THEN mi.info END) AS duration
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    mk.keywords,
    move_info.budget,
    move_info.duration,
    COUNT( DISTINCT ah.person_id ) OVER (PARTITION BY m.id) AS total_actors
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keywords mk ON m.id = mk.movie_id
LEFT JOIN 
    movie_info_extended move_info ON m.id = move_info.movie_id
LEFT JOIN 
    actor_hierarchy ah ON ci.movie_id = ah.movie_id
WHERE 
    m.production_year IS NOT NULL 
    AND ak.name IS NOT NULL
    AND (move_info.budget IS NOT NULL OR move_info.duration IS NOT NULL)
ORDER BY 
    m.production_year DESC, actor_name;
