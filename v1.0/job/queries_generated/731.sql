WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS actor_title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        co.name AS company_name,
        m.title,
        m.production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        title m ON mc.movie_id = m.id
    WHERE 
        m.production_year >= 2000
),
CombinedInfo AS (
    SELECT
        at.actor_name,
        at.title,
        at.production_year,
        ct.company_name,
        ct.production_year AS company_release_year
    FROM
        ActorTitles at
    LEFT JOIN 
        CompanyMovies ct ON at.title = ct.title AND at.production_year = ct.production_year
)
SELECT 
    ci.actor_name,
    ci.title,
    COALESCE(ci.company_name, 'Independent') AS company_name,
    ci.production_year,
    COUNT(ci.title) OVER (PARTITION BY ci.actor_name) AS title_count,
    AVG(ci.production_year) OVER (PARTITION BY ci.actor_name) AS avg_production_year,
    MIN(ci.production_year) AS first_release_year,
    MAX(ci.production_year) AS latest_release_year
FROM 
    CombinedInfo ci
WHERE 
    ci.actor_title_rank <= 5
ORDER BY 
    ci.actor_name, ci.production_year DESC;
