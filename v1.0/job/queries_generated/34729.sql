WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.person_id,
        a.name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order = 1  -- Getting main actors 

    UNION ALL

    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.person_id,
        a.name,
        ah.depth + 1 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.nr_order > 1  -- Considering additional actors
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_type AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'Director' THEN mi.info END, ', ') AS directors,
        STRING_AGG(CASE WHEN it.info = 'Producer' THEN mi.info END, ', ') AS producers
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS main_actors,
    mk.keywords,
    mit.directors,
    mit.producers,
    COALESCE(COUNT(DISTINCT c.id), 0) AS total_cast
FROM 
    title t
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    actor_hierarchy a ON t.id = a.movie_id
LEFT JOIN 
    movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info_type mit ON t.id = mit.movie_id
GROUP BY 
    t.id, mk.keywords, mit.directors, mit.producers
HAVING 
    COUNT(DISTINCT a.person_id) > 1  -- Only movies with more than one distinct actor
ORDER BY 
    t.production_year DESC,
    total_cast DESC;
