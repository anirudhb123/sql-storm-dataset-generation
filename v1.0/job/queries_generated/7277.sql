WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS rn
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
TopTitles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 10
),
MovieDetails AS (
    SELECT 
        mt.movie_id, 
        mt.company_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mt
    JOIN 
        company_name c ON mt.company_id = c.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    tt.title, 
    tt.production_year, 
    md.company_name, 
    md.company_type, 
    cd.actor_name, 
    cd.role_name
FROM 
    TopTitles tt
JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
JOIN 
    MovieDetails md ON cc.movie_id = md.movie_id
JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    tt.production_year DESC, 
    tt.title;
