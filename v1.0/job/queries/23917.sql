
WITH RecursiveActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS title_row
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    WHERE 
        m.production_year IS NOT NULL
), 
FilteredActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        RecursiveActorTitles
    WHERE 
        title_row <= 5
), 
ActorRankings AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_title) AS title_count,
        AVG(production_year) AS avg_production_year,
        STRING_AGG(movie_title, ', ') AS recent_titles
    FROM 
        FilteredActors
    GROUP BY 
        actor_id, actor_name
), 
CompanyInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        c.country_code IS NULL OR c.country_code <> 'USA'
)

SELECT 
    ar.actor_name,
    ar.title_count,
    ar.avg_production_year,
    ar.recent_titles,
    ci.company_name,
    ci.company_type,
    CASE 
        WHEN ar.avg_production_year < 2000 THEN 'Classic'
        WHEN ar.avg_production_year >= 2000 AND ar.avg_production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    ActorRankings ar
LEFT JOIN 
    CompanyInfo ci ON ar.actor_id = ci.movie_id 
WHERE 
    ar.title_count > 3
    AND (ci.company_type IS NOT NULL OR ar.avg_production_year > 2005)
ORDER BY 
    ar.title_count DESC, ar.avg_production_year ASC
LIMIT 50;
