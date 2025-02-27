WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 2000) AS production_year,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, cn.name
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_name,
        cast_count,
        aka_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        movie_details
),
popular_movies AS (
    SELECT 
        title,
        company_name,
        production_year,
        cast_count,
        aka_names
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    pm.title,
    pm.production_year,
    pm.company_name,
    pm.cast_count,
    string_agg(aka, ', ') AS aggregated_aka_names
FROM 
    popular_movies pm
LEFT JOIN 
    unnest(pm.aka_names) AS aka ON true
GROUP BY 
    pm.title, pm.production_year, pm.company_name, pm.cast_count
ORDER BY 
    pm.production_year DESC, pm.cast_count DESC;
