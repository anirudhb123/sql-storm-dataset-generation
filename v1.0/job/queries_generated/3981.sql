WITH MovieActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(t.production_year) AS average_production_year,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS unique_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info') AS info,
        t.production_year
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        aka_title t ON m.id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv show'))
),
RankedMovies AS (
    SELECT 
        ma.actor_name,
        cm.company_names,
        mi.info,
        mi.production_year,
        ROW_NUMBER() OVER (PARTITION BY ma.actor_name ORDER BY mi.production_year DESC) AS ranking
    FROM 
        MovieActors ma
    JOIN 
        CompanyMovies cm ON ma.movie_count >= 1
    JOIN 
        MovieInfo mi ON cm.movie_id = mi.movie_id
)
SELECT 
    actor_name,
    company_names,
    info,
    production_year,
    ranking
FROM 
    RankedMovies
WHERE 
    ranking <= 3
ORDER BY 
    actor_name, production_year DESC;
