WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorInfo AS (
    SELECT 
        p.name,
        c.movie_id,
        COUNT(DISTINCT c.id) AS total_roles
    FROM 
        aka_name p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    GROUP BY 
        p.name, c.movie_id
),
TopActors AS (
    SELECT 
        actor_info.name,
        SUM(actor_info.total_roles) AS total_roles_played
    FROM 
        ActorInfo actor_info
    GROUP BY 
        actor_info.name
    HAVING 
        SUM(actor_info.total_roles) > 5
),
RecentMovies AS (
    SELECT 
        title.title,
        title.production_year
    FROM 
        title
    WHERE 
        title.production_year > 2015
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    r.title,
    r.production_year,
    ta.name AS top_actor,
    COUNT(cm.company_name) AS company_count,
    CASE 
        WHEN r.production_year IS NULL THEN 'Unknown Year'
        ELSE r.production_year::text 
    END AS production_year_info
FROM 
    RankedTitles r
LEFT JOIN 
    TopActors ta ON r.year_rank <= 5
LEFT JOIN 
    CompanyMovies cm ON r.title = cm.movie_id
WHERE 
    r.title IS NOT NULL
GROUP BY 
    r.title, r.production_year, ta.name
HAVING 
    COUNT(cm.company_name) > 1
ORDER BY 
    r.production_year DESC, company_count DESC;
