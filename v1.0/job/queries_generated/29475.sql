WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cm.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cm.company_id) DESC) AS rank_by_companies
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopCompanies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        companies
    FROM 
        RankedMovies
    WHERE 
        rank_by_companies <= 5
),
ActorInfo AS (
    SELECT
        a.name AS actor_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_by_actor
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON t.id = ci.movie_id
)
SELECT 
    ti.actor_name,
    ti.title,
    ti.production_year,
    tc.company_count,
    tc.companies
FROM 
    ActorInfo ti
JOIN 
    TopCompanies tc ON ti.title = tc.title AND ti.production_year = tc.production_year
WHERE 
    ti.rank_by_actor <= 3 -- Top 3 actors for each film
ORDER BY 
    tc.production_year DESC, 
    tc.company_count DESC, 
    ti.actor_name;
