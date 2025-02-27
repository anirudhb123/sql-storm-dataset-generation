WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS lead_roles,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 1990
    GROUP BY 
        mt.id
),
FilteredMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.total_cast,
        md.lead_roles,
        md.actor_names
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 5 AND md.lead_roles > 2
),
TopMovies AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        fm.total_cast,
        fm.lead_roles,
        ROW_NUMBER() OVER (ORDER BY fm.lead_roles DESC) AS rank
    FROM 
        FilteredMovies fm
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.lead_roles,
    STRING_AGG(tm.actor_names::text, ', ') AS actor_list
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_title, tm.production_year, tm.total_cast, tm.lead_roles
ORDER BY 
    tm.lead_roles DESC, tm.movie_title ASC;
