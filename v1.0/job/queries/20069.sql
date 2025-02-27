
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
title_with_keywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(ARRAY_AGG(k.keyword), '{}') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
movie_summary AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(kw.keywords, '{}') AS keywords,
        mc.actor_name,
        mc.actor_order,
        mc.total_cast
    FROM 
        title t
    LEFT JOIN 
        title_with_keywords kw ON t.id = kw.title_id
    LEFT JOIN 
        movie_cast mc ON mc.movie_id = t.id
),
ranked_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        keywords,
        actor_name,
        actor_order,
        total_cast,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_by_cast_size
    FROM 
        movie_summary
)
SELECT 
    r.title,
    r.production_year,
    r.total_cast,
    r.keywords,
    r.actor_name,
    r.rank_by_cast_size,
    CASE 
        WHEN r.total_cast IS NULL THEN 'No Cast'
        WHEN r.total_cast > 5 THEN 'Large Cast'
        WHEN r.total_cast BETWEEN 1 AND 5 THEN 'Small Cast'
        ELSE 'No Cast Info'
    END AS cast_category,
    CASE 
        WHEN COUNT(NULLIF(r.actor_name, '')) >= 2 THEN 'Ensemble Cast'
        ELSE 'Solo Performance'
    END AS performance_type
FROM 
    ranked_movies r
LEFT JOIN 
    movie_info m ON r.title_id = m.movie_id AND m.info_type_id = 1 
WHERE 
    r.rank_by_cast_size <= 10 
    AND (r.production_year IS NOT NULL AND r.production_year >= 2000)
GROUP BY 
    r.title, r.production_year, r.total_cast, r.keywords, r.actor_name, r.rank_by_cast_size
ORDER BY 
    r.production_year DESC, r.total_cast DESC, r.rank_by_cast_size;
