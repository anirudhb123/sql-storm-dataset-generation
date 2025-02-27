WITH movie_cast AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        tt.title AS movie_title,
        tt.production_year,
        rt.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        title tt ON c.movie_id = tt.id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        tt.production_year >= 2000
        AND tt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
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

movie_info_detailed AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        mc.movie_title,
        mc.production_year,
        mc.role_name,
        mk.keywords,
        mc.actor_count
    FROM 
        movie_cast mc
    LEFT JOIN 
        movie_keywords mk ON mc.movie_id = mk.movie_id
)

SELECT 
    mid.movie_title,
    mid.production_year,
    ARRAY_AGG(DISTINCT (mid.actor_name || ' as ' || mid.role_name)) AS cast,
    mid.keywords,
    mid.actor_count
FROM 
    movie_info_detailed mid
GROUP BY 
    mid.movie_title, mid.production_year, mid.keywords, mid.actor_count
ORDER BY 
    mid.production_year DESC,
    mid.movie_title;
