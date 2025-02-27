WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.name, t.title, t.production_year
),
MovieCompanies AS (
    SELECT 
        t.id AS movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind IS NOT NULL
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    am.actor_name,
    am.role_count,
    mc.company_name,
    mc.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies am ON rt.title = am.movie_title AND rt.production_year = am.production_year
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
