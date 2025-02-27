WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
), 
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.info,
        mt.note,
        k.keyword,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_info mt
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
FullCast AS (
    SELECT 
        cc.id AS complete_cast_id,
        cc.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    rt.title,
    rt.production_year,
    md.info,
    md.keyword,
    md.company_name,
    md.company_type,
    fc.actor_name,
    fc.role_name
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
LEFT JOIN 
    FullCast fc ON rt.title_id = fc.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
