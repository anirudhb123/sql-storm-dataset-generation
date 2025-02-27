WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM NOW()) - t.production_year ORDER BY t.production_year DESC) AS recent_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInfo AS (
    SELECT 
        a.person_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(mc.companies, 'Unknown') AS companies
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieCompanies mc ON rt.title_id = mc.movie_id
    WHERE 
        rt.recent_rank <= 10
),
FinalOutput AS (
    SELECT 
        f.title,
        f.production_year,
        f.companies,
        a.actor_name,
        a.movie_count,
        CASE 
            WHEN a.movie_count > 5 THEN 'Veteran Actor'
            WHEN a.movie_count BETWEEN 3 AND 5 THEN 'Rising Star'
            ELSE 'Newbie Actor'
        END AS actor_status
    FROM 
        FilteredMovies f
    LEFT JOIN 
        ActorsInfo a ON f.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
)
SELECT 
    title,
    production_year,
    companies,
    actor_name,
    movie_count,
    actor_status
FROM 
    FinalOutput
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, movie_count DESC
LIMIT 50;

-- Optional: A bizarre safeguard clause to return NULL for actors with even movie counts, just for fun
UNION ALL
SELECT 
    NULL AS title,
    NULL AS production_year,
    NULL AS companies,
    a.actor_name,
    a.movie_count,
    'NULL Status' AS actor_status
FROM 
    ActorsInfo a
WHERE 
    a.movie_count % 2 = 0
ORDER BY 
    a.actor_name;
