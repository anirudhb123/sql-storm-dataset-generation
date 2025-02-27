WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        comp.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name
    FROM 
        aka_title t
        JOIN movie_info mi ON t.id = mi.movie_id
        JOIN movie_keyword mk ON t.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
        JOIN movie_companies mcomp ON t.id = mcomp.movie_id
        JOIN company_name comp ON mcomp.company_id = comp.id
        JOIN cast_info ci ON t.id = ci.movie_id
        JOIN role_type r ON ci.role_id = r.id
        JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND t.title ILIKE '%Adventure%'
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        movie_keyword,
        company_name,
        person_role,
        actor_name,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS rank
    FROM 
        MovieInfo 
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    movie_keyword, 
    company_name, 
    person_role, 
    actor_name
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, 
    title ASC;

