WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title, 
        at.production_year, 
        a.name AS actor_name, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER(PARTITION BY at.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year > 2000
    GROUP BY 
        at.id, at.title, at.production_year, a.name
),
FilteredMovies AS (
    SELECT 
        md.movie_title, 
        md.production_year, 
        md.actor_name,
        md.company_count
    FROM 
        MovieDetails md
    WHERE 
        md.actor_rank <= 3
)
SELECT 
    fm.movie_title, 
    fm.production_year, 
    STRING_AGG(fm.actor_name, ', ') AS top_actors,
    COALESCE(fm.company_count, 0) AS total_companies
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_title = mi.info
GROUP BY 
    fm.movie_title, fm.production_year
ORDER BY 
    fm.production_year DESC, total_companies DESC;
