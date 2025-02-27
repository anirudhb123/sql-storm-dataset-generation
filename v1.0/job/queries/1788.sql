WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        MAX(t.production_year) OVER() AS latest_production_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
Insight AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        CASE 
            WHEN md.cast_count > 10 THEN 'Blockbuster'
            WHEN md.cast_count > 5 THEN 'Moderate'
            ELSE 'Low'
        END AS movie_category,
        md.actor_names,
        md.latest_production_year
    FROM 
        MovieDetails md
    WHERE 
        md.production_year = md.latest_production_year
)
SELECT 
    i.title,
    i.production_year,
    i.cast_count,
    i.movie_category,
    i.actor_names,
    CASE 
        WHEN i.latest_production_year IS NOT NULL THEN 
            CONCAT('Latest movie produced in ', i.latest_production_year)
        ELSE 
            'No movies produced recently'
    END AS latest_movie_status
FROM 
    Insight i
JOIN 
    movie_info mi ON i.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    AND (i.production_year IS NULL OR i.production_year > 2010)
ORDER BY 
    i.cast_count DESC, i.title;
