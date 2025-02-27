WITH LatestMovies AS (
    SELECT 
        at.id AS title_id, 
        at.title, 
        at.production_year, 
        at.kind_id 
    FROM 
        aka_title at 
    WHERE 
        at.production_year = (SELECT MAX(production_year) FROM aka_title)
), ActorRoles AS (
    SELECT 
        ai.person_id, 
        ci.movie_id, 
        rt.role 
    FROM 
        cast_info ci 
    JOIN 
        role_type rt ON ci.role_id = rt.id 
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id 
    WHERE 
        ai.name IS NOT NULL
), CompanyDetails AS (
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
), MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
) 
SELECT 
    lm.title, 
    lm.production_year, 
    ar.person_id, 
    ar.role, 
    cd.company_name, 
    cd.company_type, 
    array_agg(mk.keyword) AS keywords 
FROM 
    LatestMovies lm 
LEFT JOIN 
    ActorRoles ar ON lm.title_id = ar.movie_id 
LEFT JOIN 
    CompanyDetails cd ON lm.title_id = cd.movie_id 
LEFT JOIN 
    MovieKeywords mk ON lm.title_id = mk.movie_id 
GROUP BY 
    lm.title, lm.production_year, ar.person_id, ar.role, cd.company_name, cd.company_type 
ORDER BY 
    lm.production_year DESC, lm.title;
