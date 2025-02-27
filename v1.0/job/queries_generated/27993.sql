WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.title_kind,
        pr.actor_name,
        pr.role_type,
        ci.company_name,
        ci.company_type
    FROM 
        RankedTitles rt
    LEFT JOIN 
        PersonRoles pr ON rt.title_id = pr.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rt.title_id = ci.movie_id
)
SELECT 
    movie.title_id,
    movie.title,
    movie.production_year,
    movie.title_kind,
    string_agg(DISTINCT CONCAT(movie.actor_name, ' as ', movie.role_type), '; ') AS full_cast,
    string_agg(DISTINCT CONCAT(movie.company_name, ' (', movie.company_type, ')'), '; ') AS production_companies
FROM 
    MovieDetails movie
GROUP BY 
    movie.title_id, movie.title, movie.production_year, movie.title_kind
ORDER BY 
    movie.production_year DESC, movie.title;
