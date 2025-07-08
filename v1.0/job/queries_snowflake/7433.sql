
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        movie_companies mt
    JOIN 
        company_name c ON mt.company_id = c.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), CompleteCastDetails AS (
    SELECT 
        cc.movie_id,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    md.company_name,
    md.company_type,
    ccd.actors,
    ccd.roles
FROM 
    RankedTitles rt
JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
JOIN 
    CompleteCastDetails ccd ON md.movie_id = ccd.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC,
    rt.title;
