WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        rt.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
), 
MovieKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        t.title AS movie_title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.actor_role,
    mk.keyword,
    cd.company_name,
    cd.company_type
FROM 
    ActorMovies am
LEFT JOIN 
    MovieKeywords mk ON am.movie_title = mk.movie_title
LEFT JOIN 
    CompanyDetails cd ON am.movie_title = cd.movie_title
ORDER BY 
    am.production_year DESC, 
    am.actor_name, 
    cd.company_name;
