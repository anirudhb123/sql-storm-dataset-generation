WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
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
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Plot' THEN mi.info END) AS plot,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.role,
    mk.keywords,
    mif.plot,
    mif.rating
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    movie_info_filtered mif ON rm.id = mif.movie_id
WHERE 
    rm.rn = 1
  AND 
    (mif.rating IS NOT NULL OR rm.production_year > 2010)
ORDER BY 
    rm.production_year DESC, rm.title ASC
LIMIT 100;
