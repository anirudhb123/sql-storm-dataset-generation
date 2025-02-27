WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(CAST(COUNT(DISTINCT c.person_id) AS INTEGER), 0) AS number_of_actors,
        COALESCE(GROUP_CONCAT(DISTINCT p.name ORDER BY p.name), 'No actors') AS actor_names
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        aka_name p ON p.person_id = c.person_id
    WHERE 
        cc.status_id IS NULL -- Only include movies with complete casts
    GROUP BY 
        m.movie_id, m.title
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT comp.id) AS company_count,
        STRING_AGG(DISTINCT comp.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON comp.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.number_of_actors,
    md.actor_names,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(mc.companies, 'No companies') AS companies
FROM 
    MovieDetails md
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = md.movie_id
WHERE 
    md.number_of_actors > 0
    AND (md.production_year > 1990 OR md.actor_names LIKE '%John%')
ORDER BY 
    md.production_year DESC, 
    md.number_of_actors DESC
LIMIT 100;
