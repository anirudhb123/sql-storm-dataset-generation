WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS actor_percentage,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id 
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id 
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        md.actor_percentage,
        md.cast_names,
        ROW_NUMBER() OVER (ORDER BY md.total_cast DESC) AS rn
    FROM 
        movie_details md
)
SELECT 
    COALESCE(tm.title, 'N/A') AS movie_title,
    COALESCE(tm.production_year, 'Unknown') AS movie_year,
    COALESCE(tm.total_cast, 0) AS cast_count,
    COALESCE(tm.actor_percentage, 0) AS actor_ratio,
    CASE
        WHEN tm.actor_percentage IS NULL THEN 'Data not available'
        WHEN tm.actor_percentage > 50 THEN 'Mostly Actors'
        ELSE 'Not Mostly Actors'
    END AS actor_summary,
    CASE 
        WHEN LENGTH(tm.cast_names) > 0 THEN tm.cast_names
        ELSE 'No Cast Information'
    END AS cast_list
FROM 
    top_movies tm
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC;
