WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        cm.movie_id,
        COUNT(*) AS total_roles,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        complete_cast cm ON c.movie_id = cm.movie_id
    GROUP BY 
        c.person_id, cm.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(am.total_roles, 0) AS total_roles,
        am.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    WHERE 
        rm.rn <= 10
),
MovieDetails AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.total_roles,
        COALESCE(SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS production_companies,
        COALESCE(NULLIF(STRING_AGG(DISTINCT cn.name, ', '), ''), 'Unknown') AS company_names,
        COALESCE(NULLIF(STRING_AGG(DISTINCT kw.keyword, ', '), ''), 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_companies mc ON fm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        fm.title, fm.production_year, fm.total_roles
)
SELECT 
    *,
    CASE 
        WHEN total_roles > 10 THEN 'Ensemble Cast'
        WHEN total_roles BETWEEN 5 AND 10 THEN 'Notable Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, total_roles DESC;
