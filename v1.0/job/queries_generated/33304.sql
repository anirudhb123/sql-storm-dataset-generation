WITH RECURSIVE movie_hierarchy AS (
    -- CTE to define the hierarchy of movies
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = 1  -- Assuming '1' represents the "sequel" type

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = 1
),
keyword_counts AS (
    -- CTE to count keywords per movie
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
cast_counts AS (
    -- CTE to count number of actors in each movie
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    t.title,
    t.production_year,
    k.keyword_count,
    c.actor_count,
    COALESCE(mh.depth, 0) AS hierarchy_level,
    CHAR_LENGTH(t.title) AS title_length,
    SUBSTRING(t.title FROM '([A-Z]+)') AS first_letter,
    CASE 
        WHEN t.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(t.production_year AS TEXT)
    END AS production_year_display
FROM 
    title t
LEFT JOIN 
    keyword_counts k ON t.id = k.movie_id
LEFT JOIN 
    cast_counts c ON t.id = c.movie_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year >= 2000
    AND k.keyword_count > 0
    AND (c.actor_count IS NULL OR c.actor_count < 5) -- Movies with fewer than 5 actors or NULL count
ORDER BY 
    t.production_year DESC,
    k.keyword_count DESC,
    c.actor_count ASC
LIMIT 50;
