WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
TopActors AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank = 1
),
MovieCompanies AS (
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
),
CombinedInfo AS (
    SELECT 
        t.actor_name,
        t.movie_title,
        t.production_year,
        mc.company_name,
        mc.company_type
    FROM 
        TopActors t
    LEFT JOIN 
        MovieCompanies mc ON t.production_year = mc.movie_id
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'Unknown') AS company_type
FROM 
    CombinedInfo
WHERE 
    (production_year BETWEEN 2000 AND 2020)
    OR (actor_name IS NOT NULL AND movie_title IS NOT NULL)
ORDER BY 
    production_year DESC, actor_name;
