WITH ActorStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.id, a.name
),

HighProductionYearMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        MAX(t.production_year) AS latest_production_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title
),

CompanyParticipation AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(cp.company_count, 0) AS number_of_companies,
        CASE 
            WHEN stats.movie_count IS NULL THEN 'No Actors'
            ELSE 'Starring ' || stats.movie_count || ' Actors'
        END AS actor_info
    FROM 
        aka_title t
    LEFT JOIN 
        CompanyParticipation cp ON t.id = cp.movie_id
    LEFT JOIN 
        ActorStats stats ON t.id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name))
)

SELECT 
    md.movie_id,
    md.title,
    md.number_of_companies,
    md.actor_info,
    hs.latest_production_year
FROM 
    MovieDetails md
JOIN 
    HighProductionYearMovies hs ON md.movie_id = hs.title_id
WHERE 
    md.number_of_companies > 0
ORDER BY 
    hs.latest_production_year DESC, 
    md.title ASC;

-- This query provides a summary of movies that have actors and companies involved, 
-- detailing movie titles, number of companies, and additional actor information, 
-- while implementing various SQL constructs like CTEs, aggregations, outer joins, 
-- string expressions, and NULL logic.
