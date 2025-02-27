WITH RECURSIVE related_movies AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.movie_id = (SELECT id FROM title WHERE title = 'The Godfather' LIMIT 1)

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        r.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        related_movies r ON ml.movie_id = r.linked_movie_id
    WHERE 
        r.depth < 3  -- Limit depth to 3 for performance
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT ak.name, ', ') AS actors,
        MIN(ci.nr_order) AS first_actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        string_agg(DISTINCT mt.info, '; ') AS movie_infos
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%Award%'  -- Filter for award-related info
    GROUP BY 
        mi.movie_id
)

SELECT 
    t.title,
    t.production_year,
    rm.linked_movie_id AS related_movie_id,
    mc.actors,
    mis.movie_infos
FROM 
    title t
LEFT JOIN 
    related_movies rm ON t.id = rm.movie_id
LEFT JOIN 
    movie_cast mc ON mc.movie_id = t.id
LEFT JOIN 
    movie_info_summary mis ON mis.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND (mc.first_actor_order IS NULL OR mc.first_actor_order < 5)  -- Exclude movies with more than 5 actors
ORDER BY 
    t.production_year DESC, t.title;
