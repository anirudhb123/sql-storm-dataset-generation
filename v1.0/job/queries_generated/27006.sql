WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year >= 2000
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
complete_details AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        mc.movie_title,
        mc.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        movie_cast mc
    LEFT JOIN 
        movie_keywords mk ON mc.movie_id = mk.movie_id
)
SELECT 
    cd.actor_name,
    cd.movie_title,
    cd.production_year,
    cd.keywords
FROM 
    complete_details cd
WHERE 
    cd.keywords LIKE '%Action%'
ORDER BY 
    cd.production_year DESC,
    cd.actor_name;
