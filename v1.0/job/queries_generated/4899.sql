WITH MovieInfo AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(mc.movie_id) AS company_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id
),
PersonMovies AS (
    SELECT 
        ak.name AS actor_name,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE 
        ak.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mv.title,
        mv.production_year,
        COALESCE(pm.actor_name, 'Unknown') AS lead_actor,
        mv.company_count,
        mv.company_names
    FROM 
        MovieInfo mv
    LEFT JOIN 
        PersonMovies pm ON mv.title = pm.title AND pm.recent_movie_rank = 1
    WHERE 
        mv.production_year BETWEEN 2000 AND 2023
)

SELECT 
    fm.title,
    fm.production_year,
    fm.lead_actor,
    fm.company_count,
    fm.company_names
FROM 
    FilteredMovies fm
WHERE 
    fm.company_count > 0
ORDER BY 
    fm.production_year DESC, fm.title ASC
LIMIT 100;
