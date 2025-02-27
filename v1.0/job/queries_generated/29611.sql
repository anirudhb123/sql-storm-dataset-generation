WITH movie_cast AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ci.nr_order AS cast_order,
        r.role AS role
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mc.actor_name,
        mc.movie_title,
        mc.production_year,
        mc.cast_order,
        mc.role,
        ki.keywords
    FROM 
        movie_cast mc
    LEFT JOIN 
        keyword_info ki ON mc.movie_title = ki.movie_id
)
SELECT 
    md.actor_name,
    md.movie_title,
    md.production_year,
    md.cast_order,
    md.role,
    COALESCE(md.keywords, '{}'::text[]) AS movie_keywords
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.actor_name;
