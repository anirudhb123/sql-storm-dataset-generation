WITH ActorTitles AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        r.role AS role_name
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ak.name ILIKE '%Smith%'  -- Searching for actors with 'Smith' in their name
), 
MovieKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
),
CompanyDetails AS (
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
    at.actor_name,
    at.movie_title,
    at.production_year,
    at.role_name,
    mk.keywords,
    cd.company_name,
    cd.company_type
FROM 
    ActorTitles at
LEFT JOIN 
    MovieKeywords mk ON at.movie_title = mk.movie_title
LEFT JOIN 
    CompanyDetails cd ON at.movie_title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
ORDER BY 
    at.production_year DESC, at.actor_name;
