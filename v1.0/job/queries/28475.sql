WITH MovieTitles AS (
    SELECT 
        a.id AS title_id, 
        a.title, 
        a.production_year, 
        k.keyword AS movie_keyword
    FROM aka_title a
    JOIN movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year > 2000
), ActorDetails AS (
    SELECT 
        c.movie_id, 
        p.name AS actor_name, 
        r.role AS actor_role 
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role LIKE '%lead%'
), CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        comp.name AS production_company, 
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name comp ON mc.company_id = comp.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'Production'
), EnrichedMovies AS (
    SELECT 
        mt.title_id, 
        mt.title, 
        mt.production_year, 
        ad.actor_name, 
        ad.actor_role, 
        cd.production_company, 
        cd.company_type, 
        mt.movie_keyword
    FROM MovieTitles mt
    LEFT JOIN ActorDetails ad ON mt.title_id = ad.movie_id
    LEFT JOIN CompanyDetails cd ON mt.title_id = cd.movie_id
)

SELECT 
    title, 
    production_year, 
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors,
    STRING_AGG(DISTINCT production_company || ' [' || company_type || ']', ', ') AS production_info,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM EnrichedMovies
GROUP BY title, production_year
ORDER BY production_year DESC, title;
