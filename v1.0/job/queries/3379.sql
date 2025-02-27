WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
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
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        MAX(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END) AS has_actor,
        MAX(CASE WHEN r.role = 'actress' THEN 1 ELSE 0 END) AS has_actress
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    cd.cast_count,
    CASE 
        WHEN cd.has_actor = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS features_actor,
    CASE 
        WHEN cd.has_actress = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS features_actress
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
