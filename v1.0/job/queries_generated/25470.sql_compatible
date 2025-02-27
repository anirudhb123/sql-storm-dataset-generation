
WITH popular_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_infos AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(mii.info) AS infos
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.cast_count,
    pm.cast_names,
    COALESCE(mk.keywords, ARRAY[]::text[]) AS keywords,
    COALESCE(mi.infos, ARRAY[]::text[]) AS infos
FROM 
    popular_movies pm
LEFT JOIN 
    movie_keywords mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    movie_infos mi ON pm.movie_id = mi.movie_id;
