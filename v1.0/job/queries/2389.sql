WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
actor_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_number
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS movie_rating,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(ac.actor_number, 0) AS actor_count,
    mis.movie_rating,
    mis.keywords,
    (SELECT COUNT(*) FROM title) AS total_titles
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_count ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    movie_info_summary mis ON rt.title_id = mis.movie_id
WHERE 
    rt.rank = 1 
    AND (mis.movie_rating IS NOT NULL OR mis.keywords IS NOT NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
