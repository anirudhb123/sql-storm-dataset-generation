
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget_info
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actor_names,
        md.budget_info,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rn
    FROM 
        movie_details md
    WHERE 
        md.production_year IS NOT NULL 
        AND md.cast_count > 5
)
SELECT 
    fd.movie_id,
    fd.title,
    fd.production_year,
    fd.cast_count,
    fd.actor_names,
    CASE 
        WHEN fd.budget_info IS NOT NULL THEN 'Available'
        ELSE 'Not Available' 
    END AS budget_status
FROM 
    filtered_movies fd
WHERE 
    fd.rn <= 3
ORDER BY 
    fd.production_year DESC, fd.cast_count DESC;
