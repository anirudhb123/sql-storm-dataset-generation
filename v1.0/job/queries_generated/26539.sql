WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS title_rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN 
        name n ON a.person_id = n.imdb_id
    LEFT JOIN 
        role_type r ON cc.role_id = r.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
most_produced_years AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count
    FROM 
        ranked_titles
    WHERE 
        title_rank <= 5
    GROUP BY 
        production_year
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rt.title,
    rt.production_year,
    rt.company_count,
    rt.cast_names,
    mpy.movie_count
FROM 
    ranked_titles rt
JOIN 
    most_produced_years mpy ON rt.production_year = mpy.production_year
ORDER BY 
    rt.production_year DESC, rt.company_count DESC;
