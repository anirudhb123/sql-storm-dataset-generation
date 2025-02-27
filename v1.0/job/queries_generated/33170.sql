WITH RECURSIVE related_movies AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.movie_id = (SELECT id FROM title WHERE title = 'Inception')
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rm.depth + 1
    FROM 
        movie_link ml
    JOIN 
        related_movies rm ON ml.movie_id = rm.linked_movie_id
    WHERE 
        rm.depth < 3  -- Limit the depth to 3 to avoid deep recursion loops
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    r.movie_id AS related_movie_id,
    r.linked_movie_id,
    COALESCE(c.total_cast_members, 0) AS total_cast_members,
    COALESCE(c.cast_names, 'N/A') AS cast_names,
    COALESCE(m.keywords, 'N/A') AS keywords
FROM 
    title t
LEFT JOIN 
    related_movies r ON t.id = r.movie_id
LEFT JOIN 
    cast_info_summary c ON r.linked_movie_id = c.movie_id
LEFT JOIN 
    movie_info_summary m ON r.linked_movie_id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, r.depth;
