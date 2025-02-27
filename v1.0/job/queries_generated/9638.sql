WITH movie_cast AS (
    SELECT 
        c.movie_id, 
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    mc.cast_names,
    mc.total_cast_members,
    mk.keywords
FROM 
    title t
LEFT JOIN 
    movie_cast mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON t.id = mk.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
ORDER BY 
    t.production_year DESC, 
    t.title;
