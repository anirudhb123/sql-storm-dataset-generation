WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id,
        a.name,
        ct.kind AS role,
        ARRAY_AGG(DISTINCT t.title) AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        a.person_id, a.name, ct.kind
),
CompanyFilms AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    am.name AS actor_name,
    am.role AS actor_role,
    rt.title,
    rt.production_year,
    cf.company_name,
    cf.company_type
FROM 
    ActorMovies am
JOIN 
    RankedTitles rt ON am.movies @> ARRAY[rt.title]
LEFT JOIN 
    CompanyFilms cf ON cf.movie_id = rt.title_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, 
    am.name ASC;
