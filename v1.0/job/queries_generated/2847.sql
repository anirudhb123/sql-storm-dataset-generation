WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.id, a.name
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        t.title,
        t.production_year,
        am.actor_name,
        am.movie_count,
        cm.companies,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown') AS year_display
    FROM 
        title t
    JOIN 
        ActorMovies am ON t.id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT actor_id FROM ActorMovies))
    LEFT JOIN 
        CompanyMovies cm ON t.id = cm.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    CAST(year_display AS text) AS display_year,
    actor_name,
    movie_titles,
    companies,
    movie_count
FROM 
    FilteredMovies
WHERE 
    movie_count > 1
ORDER BY 
    production_year DESC, actor_name;
