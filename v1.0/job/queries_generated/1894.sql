WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id
),
title_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
combined_results AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        COALESCE(tk.keywords, 'No keywords') AS keywords
    FROM 
        movie_details md
    LEFT JOIN 
        title_keywords tk ON md.movie_id = tk.movie_id
)
SELECT 
    cr.title,
    cr.production_year,
    cr.actor_count,
    cr.actor_names,
    cr.keywords,
    CASE 
        WHEN cr.actor_count > 10 THEN 'Ensemble Cast'
        WHEN cr.actor_count >= 5 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_quality,
    ROW_NUMBER() OVER (ORDER BY cr.production_year DESC, cr.title) AS rank
FROM 
    combined_results cr
WHERE 
    cr.production_year IS NOT NULL
ORDER BY 
    cr.production_year DESC, cr.actor_count DESC;
