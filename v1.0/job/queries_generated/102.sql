WITH MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT an.name) AS actor_names,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
HighProductionYears AS (
    SELECT 
        production_year
    FROM 
        MovieDetails
    WHERE 
        production_companies > 0
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    COALESCE(hp.production_year, 'No High Production Year') AS high_production_year
FROM 
    MovieDetails md
LEFT JOIN 
    HighProductionYears hp ON md.production_year = hp.production_year
WHERE 
    md.row_num <= 10
ORDER BY 
    md.production_year DESC, md.title;
